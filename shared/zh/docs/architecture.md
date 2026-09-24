# GFV三层架构总览

GFV把Flink作业的一部分放到Velox C++引擎上执行：Flink继续负责解析、规划、调度与checkpoint，合适子计划的可执行内核则被翻译成Velox计划原生执行。三个部分协作——gluten-flink（gluten仓内的planner、loader、runtime三模块）、velox4j（Java/JNI桥）、velox（引擎本身）。

## 一次查询的路径

```text
        SQL / DataStream作业
                  |
                  v
          Flink编译线             Calcite解析+优化：
                  |               RelNode树 -> ExecNode树
                  v
        gluten-flink planner      影子ExecNode类把每个可翻译子计划
                  |               改写成Velox计划（velox4j的
                  v               PlanNode+TypedExpr）；其余留在Flink
        StreamGraph -> JobGraph
                  |
                  v
        TaskManager: open()       每个gluten算子独占一个链切片
                  |
                  v
        velox4j serde + JNI       计划序列化成JSON，只过一次JNI；
                  |                之后跨JNI的只有句柄
                  v
        velox stateful内核        反序列化 -> StatefulPlanner把算子链
                  |               组装进单线程、拉取式的StatefulTask
                  v
        数据循环（每条记录）        Flink RowData -> Arrow -> BlockingQueue
                  |               -> velox算子链；结果以Arrow向量返回、
                  v               逐行桥接回Flink
        Flink sink + checkpoint   常规sink输出；barrier触发的快照
                                  同时覆盖velox侧状态
```

| 阶段 | 发生什么 | 所属层 |
|---|---|---|
| 1 编译 | SQL经Flink常规Calcite管线变成物理ExecNode计划 | Flink table planner |
| 2 改写 | 影子ExecNode类把每个可翻译子计划变成Velox计划；其余保留Flink算子 | gluten-flink planner |
| 3 运输 | 翻译出的计划随gluten算子走过StreamGraph与JobGraph；`open()`时计划序列化成JSON、只过一次JNI | gluten-flink runtime+velox4j |
| 4 建链 | C++侧反序列化计划，在拉取式`StatefulTask`里组装算子链 | velox `experimental/stateful` |
| 5 执行 | 每条记录桥接成Arrow、压入共享队列、被velox链拉走；输出以Arrow向量返回 | 全栈 |
| 6 输出与checkpoint | 结果经常规Flink sink离开；checkpoint barrier同时快照velox状态与Flink状态 | Flink runtime |

翻译按子计划挑选而不是整作业，所以作业通常以Velox与原生Flink阶段混合的方式运行。

## 层边界

| 层 | 语言 | 职责 | 典型改动 |
|---|---|---|---|
| gluten-flink loader | Java | jar引导、session接线、原生库加载 | 加载与classloader问题 |
| gluten-flink planner | Java | Flink计划→Velox计划翻译、算子与类型映射 | 在计划中支持新算子 |
| gluten-flink runtime | Java | 算子执行驱动、状态集成、Arrow桥接 | 流语义、状态链路 |
| velox4j | Java+JNI | 计划/表达式/数据的桥、跨JNI序列化 | 跨边界的新API |
| velox `exec` | C++ | 批式算子、HashTable、RowContainer、聚合内核 | 批执行与聚合内部 |
| velox `experimental/stateful` | C++ | 有状态流式算子、keyed state、backend、timer | 有状态算子开发 |

各仓的目录级细节在flink-velox-docs-search skill的module map里；本页与该地图互补（这里讲调用路径，那里讲路径含义）。

## 各场景的落点

- 无状态表达式开发：一个函数穿三层——velox `expression`内核、velox4j暴露、gluten-flink表达式翻译。
- 有状态算子开发：主要是planner翻译加velox `experimental/stateful`（算子、状态、timer），配合runtime桥接。
- 聚合函数开发：velox聚合内核与accumulate/merge/finalize链，经planner翻译与runtime批处理暴露。
- 性能优化：全栈profile——用查询对照表与本页地图定位瓶颈层，再按验证工作流核实。

## 深入阅读

[internals](internals/index.md)系列把上图的每个阶段走到源码级：

- [计划改写](internals/plan-rewrite.md)——影子planner类怎么把Flink算子替换成Velox计划（阶段2）
- [表达式映射](internals/expression-mapping.md)——RexNode表达式怎么变成velox的TypedExpr（阶段2）
- [计划序列化](internals/plan-serde.md)——计划怎么跨JNI、变成C++对象（阶段3-4）
- [运行时执行](internals/runtime-execution.md)——每条记录的数据环、水位线、checkpoint、关闭（阶段5-6）
- [stateful算子](internals/stateful-operator.md)——StatefulOperator框架：状态、timer、窗口flush（阶段4-5）
- [单元测试](internals/unit-testing.md)——三个仓里测试怎么写、怎么跑
