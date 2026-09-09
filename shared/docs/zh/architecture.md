# GFV三层架构总览

GFV把Flink作业的一部分放到Velox C++引擎上执行：Flink继续负责解析、规划、调度与checkpoint，合适的子计划则被翻译成Velox计划原生执行。三个部分协作——gluten-flink（gluten仓内的planner、loader、runtime三模块）、velox4j（Java/JNI桥）、velox（引擎本身）。

## 一次查询的路径

Flink SQL或DataStream作业先按常规方式构建stream graph。gluten-flink planner遍历该图，挑出可翻译的子计划——受支持数据源上的投影、过滤、聚合、join、窗口与排名算子——把每个子计划转成Velox计划：算子、类型、表达式一一映射到Velox侧。翻译不了的子计划留在Flink runtime上，所以作业通常以Velox与原生Flink阶段混合的方式运行。

翻译出的计划经velox4j进入原生世界：它把Velox计划、表达式、数据包装成Java对象并经JNI序列化传入。原生侧由velox执行——批式执行走原生`exec`机制（HashTable、RowContainer、向量化聚合），带状态的流式算子跑在`experimental/stateful`扩展里（keyed执行、state backend、watermark处理）。

数据以Arrow向量经C Data Interface流回，由gluten-flink runtime桥接进Flink的数据交换，结果经常规Flink sink输出。gluten-flink loader负责整套栈的引导：jar放进flink的`lib/`后，loader在session启动时发现并接好planner、runtime与原生库，集群无需额外配置。

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
