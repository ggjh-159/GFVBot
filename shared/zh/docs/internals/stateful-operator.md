# stateful算子：velox内的流式运行时

`velox/experimental/stateful/`下的流式运行时：它怎么把批式出身的velox执行改造成无限流，以及一个新的stateful算子要实现的API。先读[运行时执行](runtime-execution.md)了解Java怎么驱动这一侧；本页讲C++内部。

三个设计决策承载一切：

1. **拉取式单线程**：`StatefulTask`继承`exec::Task`并固定`ExecutionMode::kSerial`——没有driver线程；Java每来一条数据/一次timer回调推进一轮。
2. **组合而不是重写**：`StatefulOperator`是个壳，持有原生`exec::Operator`（无状态的FilterProject/TableScan直接复用）；有状态语义的算子继承壳来实现。
3. **统一事件模型**：数据记录、水位线、空闲标记都是`StreamElement`，同一条通道传递。

```text
+---------------- StatefulTask（exec::Task，kSerial）----------------+
|  operatorChain_ ＝ StatefulOperator链                                |
|                                                                      |
|   +------------------ StatefulOperator（壳）------------------+     |
|   | operator_     内嵌的原生exec::Operator                     |     |
|   |               （FilterProject/TableScan/HashProbe...）     |     |
|   | targets_      下游壳列表                                   |     |
|   | stateHandler_ 状态+timer句柄（有状态算子用）                |     |
|   +-----------------------------------------------------------+     |
|                                                                      |
|  推进：链头advanceWithFuture                                         |
|    -> operator_->getOutput()拉原生算子的输出                         |
|       -> pushOutput：结果 -> targets[i]->addInput+advance           |
|          （递归级联；中间没有队列；链尾把元素交给                    |
|           task的pendings_，等Java侧来取）                            |
|                                                                      |
|  事件：StreamRecord/Watermark/WatermarkStatus同通道                  |
+----------------------------------------------------------------------+
  旁路：水位线沿链processWatermark（多输入合并取最小再下发）；
  timer触发进Triggerable#onEventTime/onProcessingTime（处理时间
  回调经Java mailbox回流）；checkpoint沿链snapshotState进状态
  后端（heap显式快照；RocksDB直接读写Flink的活实例）
```

| 阶段 | 入口 | 回答的问题 |
|---|---|---|
| 1 事件模型 | `StreamElement`层级（`experimental/stateful/StreamElement.h`） | 链上流动的是什么 |
| 2 任务 | `StatefulTask::create`/`#init`/`#initStateBackend` | 拉取式任务怎么建、状态后端怎么注入 |
| 3 壳 | `StatefulOperator`（`StatefulOperator.h/.cpp`） | 原生算子怎么被包住、链怎么级联 |
| 4 组装 | `StatefulPlanner::plan`/`#transformStatefulOperators` | 新算子的组装接入点在哪 |
| 5 状态与timer | `StreamOperatorStateHandler`（`state/`） | 算子用的状态与timer API |
| 6 checkpoint | `StatefulOperator#snapshotState`+`WindowAggOperator`（gluten-flink runtime） | 快照对齐与RocksDB直通 |
| 7 样板 | `WindowAggregator`（`WindowAggregator.h`） | 以上全部拼成一个算子的样子 |

## 阶段1：统一事件模型

`StreamRecord`（载荷是`RowVectorPtr`——整条链路保持向量化）、`Watermark`（事件时间已推进到t）、`WatermarkStatus`（我这个输入暂时没数据，下游别傻等水位线）。一种元素类型意味着一条addInput/输出路径、一份级联实现；数据与控制消息不抢专用通道。

## 阶段2：任务

`StatefulTask::create`注册进任务池；构造器全部工作就是`kSerial`那个参数。`init`建链并初始化。`initStateBackend`接收Java侧参数：RocksDB参数（native句柄，见阶段6）建`RocksDBStateBackend`；否则建heap的`HashMapStateBackend`。后端注入链上每个算子。

## 阶段3：壳与级联

`StatefulOperator`的三样家当：内嵌原生算子、下游target列表、（有状态算子的）`stateHandler_`。基类虚函数构成流式生命周期API——`initialize`、`isFinished`、`addInput`、`advance`、`advanceWithFuture`、`close`、`finish`、`processWatermark`、`processWatermarkStatus`、`checkWatermarkStatus`、`initializeState`——默认实现全部"委托内嵌算子+递归targets"，纯无状态变换零代码接入。

承重方法是`pushOutput`：非链尾算子的输出直接进`targets_[i]->addInput`+`advance`（递归）；链尾把元素交给task的pendings_。一次推进让数据滚到链尾或停在某个算子里（攒窗口的）——中间不经任何队列。`finish`负责排干：noMoreInput后循环getOutput直到干——窗口算子的最后一批输出在这里flush。多输入水位线合并各输入（合取最小）并在空闲状态变化时补发状态事件，与Flink的combined watermark语义一致。

## 阶段4：组装分发

`StatefulPlanner#transformStatefulOperators`解开每个`StatefulPlanNode`、按内层节点类型分发：stateful专属节点各有定制transform（构造对应StatefulOperator子类+KeySelector+状态参数）；其余走通用包装（[计划序列化](plan-serde.md)）。**新算子的组装接入点就是这条阶梯上的一个分支。**

## 阶段5：状态与timer

每个算子一个`StreamOperatorStateHandler`，刻意对标Flink同名类。所有状态值都是`RowVectorPtr`——状态存的也是向量，与一切一致。

| API | 形态 | 典型用途 |
|---|---|---|
| `getValueState` | `ValueState<key, window, RowVectorPtr>` | 窗口聚合的累计向量 |
| `getMapState`/`getListState` | map/list变体 | 按key的集合 |
| `setCurrentKey` | 任何状态访问之前 | 与Flink keyed state纪律一一对应 |
| `createTimerService(triggerable)` | 返回`InternalTimerService` | 回调落进算子自己 |
| `snapshotState(checkpointId)` | 后端快照 | 阶段6 |

`InternalTimerService`提供`registerEventTimeTimer`/`registerProcessingTimeTimer`/`delete...`/`advanceWatermark`——事件时间timer随水位线推进触发；处理时间回调经Java mailbox回流（[运行时执行](runtime-execution.md)）。

## 阶段6：checkpoint与RocksDB直通

`StatefulOperator#snapshotState`沿链递归：内嵌算子自己的快照+状态handler的快照+`Snapshotable`内嵌算子的快照；heap后端产出显式快照记录（字符串）收集回Java侧存进Flink state store。`restoreState`与`notifyCheckpointComplete`（sink的commit）对称。

RocksDB路径是有意思的那个：velox不自建RocksDB——**直接用Flink的活实例**。Java侧`WindowAggOperator#initializeState`用反射从Flink的`RocksDBKeyedStateBackend`里挖出native句柄（db对象、读/写选项、列族句柄），连同key/accumulator类型信息打包成`RocksDBKeyedStateBackendParameters`，经`task.initializeState`传下去。C++后端随后读写同一个库。同一份RocksDB里同时有Flink原生状态和velox状态，barrier统一保一致；非RocksDB后端走上面的显式快照路径。

## 阶段7：样板

`WindowAggregator`是一切的模板：双继承（`StatefulOperator`+`Triggerable<int64_t,int64_t>`）、按需覆写生命周期钩子（`initializeState`拿ValueState与timer服务；`addInput`设当前key、注册timer；`onEventTime`/`onProcessingTime`收敛到flush；输出走`pushOutput`），两阶段local/global聚合的原生算子装在壳里。

## 新增场景：新增一个stateful算子

1. **计划节点**（velox）：`StatefulPlanNode.h`里仿`GroupAggregationNode`加节点类，带齐静态参数；`serialize()`+`static create`；注册进`StatefulPlanNode::registerSerDe()`。
2. **Java镜像**（velox4j）：`plan/`下同名同字段的PlanNode类，注册进`ISerializableRegistry`——名字完全一致（[计划序列化](plan-serde.md)）。
3. **算子**（velox）：继承`StatefulOperator`（要timer再加`Triggerable`），按阶段7的样板覆写钩子；带key的算子仿`StreamKeyedOperator`。
4. **工厂**（velox）：`transformStatefulOperators`加构造该算子的分支（阶段4）。
5. **planner侧**（gluten）：构造该节点的ExecNode覆盖（[计划改写](plan-rewrite.md)）。
6. **运行时侧**（gluten）：通常直接用`GlutenOneInputOperator`就够；特殊生命周期才写子类。

必实现API速查：节点的serialize/create/registerSerDe三件套；算子的`initialize`/`addInput`/`advance`（带状态加`initializeState`）；工厂分支；Java侧serde注册。按语义可选：`processWatermark`、`checkWatermarkStatus`、`numInputs`、`needsFinishDrain`。

## 陷阱

| 症状 | 成因 | 规避 |
|---|---|---|
| 状态访问行为异常 | 访问前没`setCurrentKey` | 先设当前key，永远 |
| 下游没被初始化 | 覆写的`initializeState`忘了递归 | 像默认实现那样递归targets |
| 输出到不了Java | 产出没走`pushOutput` | 一切经pushOutput出去；链尾进pendings |
| 事件时间timer不触发 | 它只随水位线推进 | 查水位线是否真到了该算子（空闲输入！） |
| 恢复后状态缺失 | 非RocksDB后端没有显式快照路径 | heap后端靠快照记录，不靠活实例 |
| 最后一个窗口的输出丢了 | flush发生在`finish`里 | 尊重`needsFinishDrain`与排干循环 |
