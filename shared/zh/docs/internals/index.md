# GFV internals（内部机制深入）

GFV全栈的源码级深入，[架构总览](../architecture.md)里的每个阶段各一篇。先读总览；当任务需要知道某阶段实际怎么运作、新部件接在哪时再来这里。

| 页面 | 对应总览阶段 | 回答的问题 |
|---|---|---|
| [计划改写](plan-rewrite.md) | 2 | gluten的影子planner类怎么把Flink算子替换成Velox计划；新覆盖一个ExecNode需要什么 |
| [表达式映射](expression-mapping.md) | 2 | RexNode表达式怎么变成Velox的TypedExpr；新函数两侧各要做什么 |
| [计划序列化](plan-serde.md) | 3-4 | 计划怎么以JSON跨JNI、变成C++对象与算子链 |
| [运行时执行](runtime-execution.md) | 5-6 | 每条记录的数据环：链切分、Arrow桥接、驱动循环、水位线、checkpoint、关闭 |
| [stateful算子](stateful-operator.md) | 4-5 | StatefulOperator框架：事件模型、组合壳、状态与timer API、checkpoint/RocksDB直通 |
| [单元测试](unit-testing.md) | — | velox、velox4j、gluten-flink三仓的测试怎么写、怎么跑 |

## 约定

**代码引用**：提到方法时写作`类#方法`（如`StatefulTask#next`）；提到文件时写作相对仓库根目录的路径（如`gluten-flink/planner/.../StreamExecCalc.java`，`...`表示省略的包路径）。四个源码仓（velox、velox4j、gluten、flink）克隆在工作区`repos/`目录下——在对应仓库内grep符号名即可定位源码。

**不使用行号**：源码改动后行号随即失效，类名与方法名则通常保持不变。文中一律以符号名定位源码，保证文档在代码重构后仍然可用。

**每页结构**：每篇依次是——一段引言（本篇回答什么问题）、一张流程图、阶段表、若干机制小节；结尾固定两个小节："新增X检查清单"（按步骤接入新部件的操作列表）与"陷阱表"（症状|成因|规避三列）。结尾两个小节建立在前文机制小节之上，建议按顺序阅读。
