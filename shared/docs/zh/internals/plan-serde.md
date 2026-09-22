# 计划序列化：从Java计划到C++算子链

"planner建好velox4j PlanNode树"到"Velox算子链跑起来"之间发生的事：树序列化成名字多态的JSON、以字符串过一次JNI、按名反序列化成C++对象、StatefulPlanner组装出可执行链。nexmark source与print sink怎么接进这条路径也一并讲清。

```text
Java（GlutenOneInputOperator#initSession）         C++（velox4j/velox）
  StatefulPlanNode树
   |-- mock TableScanNode(ExternalStreamTableHandle)
   |      + addTarget(真实计划子树)
   v
  Serde.toJson  --- 一个JSON字符串过JNI --->  folly::parseJson
   |   PolymorphicSerializer                       |
   |   注入"name": "ProjectNode"...                v
   ISerializableRegistry                    ISerializable::deserialize<Query>
   （Java名字↔类表）                         （C++名字↔工厂表）
                                                        |
                                                        v
                                          StatefulQueryExecutor -> StatefulTask::create
                                                        |        （kSerial，拉取式）
                                                        v
                                          StatefulPlanner::plan -> StatefulOperator链
                                          （每个壳内嵌一个原生exec::Operator）
```

| 阶段 | 入口 | 回答的问题 |
|---|---|---|
| 1 Java序列化 | `Serde#toJson`、`PolymorphicSerializer`、`ISerializableRegistry`（velox4j`serde/`、`serializable/`） | 多态树怎么变JSON、新类在哪注册 |
| 2 JNI边界 | `JniWrapper.createQueryExecutor`（velox4j，Java侧+`JniWrapper.cc`） | 边界上到底传什么 |
| 3 C++反序列化 | `ISerializable::deserialize`、各类的`registerSerDe()`（velox`common/serialization/Serializable.h`） | JSON怎么变成`core::PlanNode`对象 |
| 4 建链 | `StatefulQueryExecutor`→`StatefulTask::init`→`StatefulPlanner::plan`（velox4j、velox`experimental/stateful/`） | PlanNode怎么变成可执行算子 |
| 5 连接器 | `NexmarkConnector`、`ExternalStream`、print sink（velox`experimental/connectors/`） | source与sink怎么插进来 |

## 阶段1：名字多态序列化

跨JNI的对象都实现`NativeBean`；序列化器在对象自身字段之前写一个`"name"`字段（如`"ProjectNode"`），反序列化按它路由。注册在`ISerializableRegistry`的静态块里——三组：表达式（`CallTypedExpr`等）、connector句柄（`NexmarkTableHandle`）、计划节点（`ProjectNode`、`TableScanNode`、`StatefulPlanNode`、`EmptyNode`、各stateful节点）。没有注解；**注册即命名**——未注册的类序列化直接失败。

两个要带着走的结构性事实：

- 每个gluten算子的计划必须有source（velox拒绝无source计划），而真实数据来自Flink。所以`initSession`把真实子树作为mock`TableScanNode(ExternalStreamTableHandle)`的target挂上——由队列供数的拉取式扫描（[运行时执行](runtime-execution.md)）。planner阶段的`EmptyNode`占位在此兑现。
- `StatefulPlanNode`是"入口节点+下游target列表"——让线性算子链能表达成列表，与C++侧同名类一一对应。

`initSession`里的`"Gluten Plan: {}"`调试日志打出完整JSON——怀疑计划不对时的第一站，也是serde往返测试的现成输入（[单元测试](unit-testing.md)）。

## 阶段2：JNI边界

`queryOps().execute(query)`落到native的`createQueryExecutor(String)`。载荷是一个JSON字符串——只此一次。C++侧解析、反序列化出`Query`、创建`StatefulQueryExecutor`、存进session的`ObjectStore`；返回的64位句柄是后续所有调用（advance、get、snapshot...）的凭证，计划不再过边界。原生库在第一次触碰velox4j类时加载（TaskManager日志里的`Initializing Velox4J`行）。

## 阶段3：按名反序列化

每个`ISerializable`子类把静态`create(const folly::dynamic&, void*)`工厂注册进反序列化注册表；`deserialize<T>`读`"name"`字段查表构造。Java与C++两个注册表对称；**名字字符串是唯一契约**。注册点：

- 通用计划节点：`velox/core/PlanNode.cpp`的`PlanNode::registerSerDe()`（约30个）
- stateful扩展节点：`StatefulPlanNode.cpp`的registerSerDe——`StatefulPlanNode`自己（递归反序列化`node`+`targets`）、`EmptyNode`、`WatermarkAssignerNode`、`StreamJoinNode`、`GroupAggregationNode`、`DeduplicateNode`等
- connector句柄/split：各自connector的cpp里，`registerConnectors()`把`connector-nexmark`、`connector-external-stream`等名字绑到工厂

所有`registerSerDe`在velox4j初始化时统一执行——C++新节点类型＝"类+一行Register"，没有中心化配置。

## 阶段4：StatefulPlanner组装

`StatefulQueryExecutor`把计划包进`PlanFragment`+`QueryCtx`，调`StatefulTask::create`——固定`ExecutionMode::kSerial`的`exec::Task`子类（[stateful算子](stateful-operator.md)）——然后`StatefulTask#init`→`initOperators`→`StatefulPlanner::plan`。

分发是对内层节点的类型阶梯：stateful专属节点各有定制transform（水位线分配、stream join、group/window聚合...）；其余走`transformGenericOperator`→`transformOperator`，把PlanNode映到原生算子：

| PlanNode | 原生算子 |
|---|---|
| `FilterNode`（后随`ProjectNode`） | `exec::FilterProject`——两者融合；"gluten-calc"的真身 |
| `TableScanNode` | `exec::TableScan` |
| `HashJoinNode` | `exec::HashProbe` |
| `AggregationNode` | `exec::StreamingAggregation` |
| `TopNNode` | `exec::TopN` |

最后兜底查`exec::Operator::operatorSupplierFromPlanNode`——经`Operator::registerOperator`扩展的点。

## 阶段5：连接器

- **nexmark source**：`TableScanNode`+`NexmarkTableHandle("connector-nexmark")`→`NexmarkConnector`；`addSplit`接收计划期构造的`NexmarkParallelSplit`，`next()`按wallclock驱动生成器。生成与shuffle全在C++内。
- **print sink**：`TableWriteNode("connector-print")`→C++直接写stdout；TaskManager`.out`日志里的`N> +I[...]`行就是它的输出，`N>`是sink子任务号。完全绕开Java collector（[运行时执行](runtime-execution.md)）。
- **流输入**：`ExternalStreamTableHandle`→`ExternalStream`连接器，从共享`BlockingQueue`拉Arrow批。

## 新增场景：新的计划节点/connector

新计划节点类型：

1. velox4j：`plan/`下的`PlanNode`子类（字段即JSON字段）；注册进`ISerializableRegistry`的plan-node组。
2. velox：同语义`core::PlanNode`子类，实现`serialize()`与`static create(...)`；注册进对应的`registerSerDe()`——名字必须与Java侧完全一致。
3. 翻译：`transformGenericOperator`兜不住就在`StatefulPlanner`加分支（完整算子API见[stateful算子](stateful-operator.md)）。
4. gluten侧构造该节点的代码就是ExecNode覆盖那步（[计划改写](plan-rewrite.md)）。

新connector：Java侧split/handle子类+注册表entry；C++侧实现`connector::Connector`（`addSplit`+数据游标），以`connector-myname`注册；Flink侧实现一个`VeloxSourceSinkFactory`。

## 陷阱

| 症状 | 成因 | 规避 |
|---|---|---|
| 序列化报`not registered` | Java类没进`ISerializableRegistry` | 补entry——注册即命名 |
| 反序列化拒绝未知`name` | C++缺`registerSerDe`，或两侧名字拼写不一致 | 名字两侧逐字节一致 |
| 怀疑计划JSON | — | 抓`"Gluten Plan: {}"`调试输出比对；喂给serde往返测试 |
| 运行的链里算子不对 | 某个transform分支接走（或漏接）了节点 | 先查`StatefulPlanner`分发阶梯再怀疑serde |
