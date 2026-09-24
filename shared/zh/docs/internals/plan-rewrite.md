# 计划改写：Flink ExecNode怎么变成Velox计划

gluten怎么在不改Flink任何jar的前提下改写物理计划：同包影子类赢下类加载竞争，其`translateToPlanInternal`构建的是Velox计划而不是Flink算子。本页讲机制、覆盖清单、以及新覆盖一个ExecNode需要什么。

```text
SQL
 |
 v
Flink编译线：Calcite解析+优化
 |  RelNode树 -> ExecNode树（物理计划）
 v
PlannerModule（gluten-flink loader模块）
 |  解包两份内嵌jar到临时目录：
 |    gluten-flink-planner.jar（薄jar，约14个影子类）在前
 |    flink-table-planner.jar（官方planner）在后
 v
PlannerComponentClassLoader
 |  org.apache.flink...下的类只从这两份jar里加载，
 |  且gluten jar先查——同名类，gluten赢
 v
ServiceLoader -> DefaultPlannerFactory -> StreamPlanner（一行未改）
 |  StreamPlanner实例化的每个ExecNode类都经过同一个
 |  类加载器加载——跑起来的正是影子副本
 v
影子ExecNode类（14个）
 |  translateToPlanInternal：先翻译输入边，再构建velox4j
 |  PlanNode子树，包进GlutenOneInputOperator（只持计划，
 |  无序列化、无JNI）
 v
Transformation -> StreamGraph   （web UI上显示"gluten-calc"等）
```

| 阶段 | 入口 | 回答的问题 |
|---|---|---|
| 1 引导与隔离 | `PlannerModule`构造器+`PlannerModule#loadPlannerFactory`（gluten-flink loader） | JVM为什么加载gluten那份同名类 |
| 2 覆盖面 | `org.apache.flink.table.planner.plan.nodes.exec`下的影子类（gluten-flink planner） | 哪些ExecNode被改写 |
| 3 改写样板 | `StreamExecCalc#translateToPlanInternal`（gluten-flink planner） | 一个Calc怎么变成FilterNode+ProjectNode子树 |
| 4 source与sink | `StreamExecTableSourceScan`、`VeloxSourceSinkFactory#buildSource/buildSink`（gluten-flink runtime）、`NexmarkSourceFactory` | 对接外部系统的两端怎么整体换掉 |

## 阶段1：类加载隔离

利用的JVM规则：一个全名类只加载一次，谁先加载谁定义。Flink本来就把table planner放在隔离类加载器里跑；gluten把自己的影子jar排进同一个加载器的更前面。

| 包前缀命中 | 从哪加载 | 例子 |
|---|---|---|
| `COMPONENT_CLASSPATH`（`org.apache.flink`、`org.apache.gluten`等） | 只查两份内嵌jar，gluten在前 | `StreamExecCalc` |
| `OWNER_CLASSPATH`（日志、janino、commons、hadoop） | 外层AppClassLoader | slf4j |
| 都不命中 | 仅组件内，不回退外层 | jackson |

第三行解释了planner jar为什么必须同时留在flink的`lib/`里：source/sink工厂的ServiceLoader发现在外层类加载器上执行。删掉它，翻译阶段报jackson`ClassNotFoundException`。

## 阶段2：覆盖了什么

影子类与Flink原类逐字段一致（保证JSON物理计划照常加载），唯一改写的是`translateToPlanInternal`。

| 影子类 | 生成的Velox计划节点 | 运行时算子 |
|---|---|---|
| `StreamExecCalc` | `FilterNode`+`ProjectNode` | GlutenOneInputOperator（"gluten-calc"） |
| `StreamExecTableSourceScan` | 经source工厂（如`TableScanNode`+`NexmarkTableHandle`） | GlutenStreamSource |
| `StreamExecGroupAggregate`等4个聚合节点 | `AggregationNode` | WindowAggOperator等 |
| `StreamExecRank` | `TopNNode` | — |
| `StreamExecDeduplicate` | `DeduplicateNode` | — |
| `StreamExecJoin`/`StreamExecWindowJoin` | `TableScanNode`+`HashPartitionFunctionSpec`+`NestedLoopJoinNode`等 | GlutenTwoInputOperator |
| `StreamExecExchange` | —（hash分区表达） | 名字"exchange-hash" |
| `StreamExecWatermarkAssigner` | `ProjectNode` | — |
| `CommonExecSink` | 经sink工厂（如`TableWriteNode`） | GlutenStreamingFileWriterOperator等 |

## 阶段3：改写样板（StreamExecCalc）

所有影子类都走同样四步：

1. 先翻译输入边（`ExecEdge#translateToPlan`），保证上游链路（可能混着原生与gluten节点）先建好。
2. 构建Velox子树：WHERE条件变成`FilterNode`，投影变成`ProjectNode`，根上放`EmptyNode`占位。占位是有意的：每个gluten算子只描述"自己这段"；运行时`open()`会把占位换成队列供数的ExternalStream扫描节点（见[运行时执行](runtime-execution.md)）。
3. 子树包进`StatefulPlanNode`交给`GlutenOneInputOperator`——只持计划，无序列化、无JNI，那些都发生在TaskManager上。
4. 返回Transformation。与原生Flink唯一可见的差别是web UI上的算子名（"gluten-calc"）。

明显缺席的是codegen：原生Flink在这里把表达式编译成Java字节码；gluten保留表达式树，留给velox在C++侧编译成向量化执行（见[表达式映射](expression-mapping.md)）。

## 阶段4：source与sink改写

两端没法做"纯计算"，路线不同：先让Flink生成原生Transformation，再整个换掉。

- `StreamExecTableSourceScan#translateToPlanInternal`先调`super()`（原生SourceTransformation）、顺手提取水位线下推规格，然后把Transformation交给`VeloxSourceSinkFactory#buildSource`。
- `buildSource`/`buildSink`两路找工厂：ServiceLoader（上面的`lib/`发现），然后按硬编码的`FACTORY_CLASS_NAMES`清单反射加载。每个工厂实现`match(transformation)`+`buildVeloxSource/...`。
- 没有工厂命中时warn并原样返回原生Transformation：不支持的source/sink**静默降级**回原生执行，查询照样能跑。（对比：表达式映射没有兜底——查不到映射直接失败。）
- 例子：`NexmarkSourceFactory`用反射从原生source里取出generator配置，构建`TableScanNode`+`NexmarkTableHandle`+`NexmarkParallelSplit`，包进`GlutenStreamSource`，返回一个对StreamGraph来说"什么都没发生过"的`LegacySourceTransformation`。

## 新增场景：覆盖一个新的ExecNode

1. 同包路径、与Flink原类完全一致的`@ExecNodeMetadata` name与version——不需要注册动作，加载顺序本身完成覆盖。
2. 在`translateToPlanInternal`里把恒等投影示例换成真实节点：表达式用`RexNodeConverter#toTypedExpr`（[表达式映射](expression-mapping.md)）；velox4j没有的节点类型要造新PlanNode类（[计划序列化](plan-serde.md)）。
3. source/sink类节点另需工厂（`match`+`buildVeloxSource`），注册进`VeloxSourceSinkFactory.FACTORY_CLASS_NAMES`与`META-INF/services`文件。
4. 部署：planner jar有两个身份——loader jar内嵌的薄jar+`lib/`里供ServiceLoader的那份。重编后两处都要替换。

## 陷阱

| 症状 | 成因 | 规避 |
|---|---|---|
| web UI上只有原生算子 | 影子类输掉了类加载竞争（部署顺序不对） | 覆盖的translator类必须排在classpath最前 |
| 翻译阶段jackson`ClassNotFoundException` | `lib/`里缺planner jar（仅组件内加载不回退） | 把planner jar放回`lib/` |
| 作业在计划加载阶段失败 | 影子类`@ExecNodeMetadata`与Flink原类不一致 | name/version保持逐字节一致 |
| 某个source/sink悄悄跑原生 | 没有工厂命中（未注册或`match`太窄） | 查warn日志；注册或放宽`match` |
