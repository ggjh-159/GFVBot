# 运行时执行：每条记录的数据环

JobGraph下发之后发生的事：gluten算子在Flink的task线程里怎么组织、`open()`怎么把C++侧立起来、每条记录怎么走Java→Arrow→队列→Velox链→回来、以及旁路（水位线、处理时间timer、checkpoint、关闭）怎么保持线程安全。链本身的C++内部是[stateful算子](stateful-operator.md)那一页。

```text
JobGraph生成
 |  每个gluten算子独占一个链切片；两头都是gluten→
 |  直传Arrow（StatefulRecord），否则退回RowData
 v
TaskManager：算子open()（一次性）
 |  1 桥     2 session资源    3 BlockingQueue（凭id跨JNI共享）
 |  4 mock ExternalStream输入+真实计划 -> JSON -> execute -> task句柄
 |  5 addSplit把队列绑到scan节点；noMoreSplits封口
 |  6 注册native回调入口
 v
+---------------- 每条记录/每次触发 ----------------+
| Flink上游 -- RowData --> processElement            |
|   1 inputBridge：1行→1行的Arrow RowVector，         |
|     尾部补$row_kind TINYINT列                       |
|   2 inputQueue.put --共享BlockingQueue-->          |
|        C++侧TableScan(ExternalStream)::next拉走     |
|        StatefulTask::next推链一轮；                  |
|        结果落进task的pendings                        |
|   3 processElementInternal -> drainTaskOutput循环： |
|        task.advance() -> statefulGet()              |
|        Watermark -> emitWatermark | Status -> 发状态 |
|        Record -> outputBridge逐行转RowData，         |
|                  下游是gluten则StatefulRecord直通     |
|                  （Arrow不拆）                        |
|  BLOCKED＝暂无输出等下次触发；                        |
|  FINISHED＝流结束                                     |
+-----------------------------------------------------+
旁路：水位线入：processWatermark -> task.notifyWatermark，
     随后拉一把输出。timer出：C++ -> NativeCallbackBridge ->
     Java mailbox -> drainTaskOutput（绝不新开线程）。
     checkpoint：barrier -> snapshotState -> 同步
     task.snapshotState。恢复：initializeState。
close()：解绑回调 -> 关task -> noMoreInput ->
         关队列 -> 注销session -> 关session资源
```

| 阶段 | 入口 | 回答的问题 |
|---|---|---|
| 1 JobGraph | `OffloadedJobGraphGenerator`（gluten-flink runtime） | 链切分与Arrow直通决策 |
| 2 open | `GlutenOneInputOperator#initSession`/`#open` | C++任务怎么建起来 |
| 3 上行 | `GlutenOneInputOperator#processElement`+`FlinkRowToVLVectorConvertor#fromRowData` | 一行怎么变成队列里的Arrow批 |
| 4 拉取 | `ExternalStreamDataSource#next`（velox4j）+`BlockingQueue#read` | C++怎么取数、"暂时没有"怎么表达 |
| 5 驱动循环 | `GlutenOneInputOperator#drainTaskOutput`→JNI`advance0`→`StatefulTask#next` | 结果怎么回Java、谁驱动下一轮 |
| 6 水位线与timer | `#processWatermark`、`#onProcessingTime`、mailbox | 旁路信号怎么无竞态跨界 |
| 7 checkpoint | `#snapshotState`/`#initializeState`/`#notifyCheckpointComplete` | 状态怎么保持一致 |
| 8 close | `GlutenOneInputOperator#close` | 清理顺序与背后的道理 |

## 阶段1：链切分与直通决策

一个链切片只允许一个gluten算子——各持各的StatefulTask，两个gluten算子绝不挤同一个Task线程。生成器对每个算子问：上游切片也是gluten吗？下游呢？两头都是gluten→中间传`StatefulRecord`（Arrow向量整批直传，不做Arrow→RowData→Arrow往返——吞吐的关键决策之一）；任一端原生→该侧退回RowData。生成器按决策克隆算子并经`GlutenOneInputOperatorFactory`安装——必须走这个工厂，普通`setStreamOperator`会把它包进一个跳过mailbox绑定的工厂（阶段6靠它）。

## 阶段2：open()七步

`initSession`在task生命期里跑一次：(1)按声明的类选输入/输出桥；(2)session资源（velox4j Session+Arrow分配器）；(3)Java侧建BlockingQueue——C++稍后凭id从ObjectStore取回同一对象；(4)建mock ExternalStream输入计划并序列化+execute（[计划序列化](plan-serde.md)）；(5)`addSplit`把队列绑到scan节点、`noMoreSplits`封口；(6)`bindNativeCallbackTarget`注册timer回调入口；(7)完毕——名为`task`的句柄是之后一切的接口。

## 阶段3：上行，一次一行

每条记录调一次`processElement`：转换、put、随即`processElementInternal()`——来一条推一轮。转换（`fromRowData`）为每条RowData建一个**1行**的RowVector：Java侧不攒批（向量化攒批在velox内部完成；nexmark这类connector本来就整批到达）。尾部`$row_kind` TINYINT列把Flink的行种类（+I/-D/-U镜像）带进velox；列名字符串是与C++侧共享的契约——入侧剥离、出侧补回。所有权：这里只关"自己造"的向量——直通向量属于上游（Arrow内存引用计数；不守规则的另一头是双重free）。

## 阶段4：C++拉取与"暂时没有"

`ExternalStreamDataSource#next`从split绑定的队列读。`BlockingQueue#read`语义：有数据→弹出返回；空且FINISHED→`nullptr`（优雅流结束，触发finish级联）；空且仍OPEN→`nullopt`——"暂时没有"。上游velox4j在此处原有的异步promise等待被这个fork整段禁用，整个体系因此是**纯拉取式**：C++绝不阻塞等数据；控制权回Java，下次触发再试。这一段被禁用的代码是整个执行模型的承重墙。

## 阶段5：驱动循环

每次触发跑`drainTaskOutput`：调`task.advance()`（JNI`advance0`→`StatefulTask#next`——先清未取走的旧输出，再推整条链一轮）。三态：AVAILABLE→`statefulGet()`取回Java侧`StatefulElement`，按种类分派（水位线/空闲状态/记录），取完**显式close**——它持有native句柄。BLOCKED或FINISHED→退出循环等下次触发。输出转换（`toRowData`）把多行向量逐行拆出、尊重`$row_kind`。两个例外：print sink的输出不走这座桥（C++直接打印，见[计划序列化](plan-serde.md)）；下游是gluten时`StatefulRecord`整批直通。

## 阶段6：水位线与timer走mailbox

水位线下行：`processWatermark`→`task.notifyWatermark`（窗口触发全在C++），随后照例拉一把输出。上行（timer）：C++处理时间timer触发Java回调，回调只做一件事——往Flink mailbox排一个`drainTaskOutput`。C++绝不自己开线程碰Java；一切经mailbox回流，与记录处理、barrier处理串行。各入口检查的`closing`标志防止已排队的残留回调复活关闭中的算子。

## 阶段7：checkpoint

barrier对齐时Flink调`snapshotState`→同步`task.snapshotState`（JNI）→C++沿链快照进Flink state store（具体快照什么、以及跳过序列化的RocksDB直通见[stateful算子](stateful-operator.md)）。恢复：重启后`initializeState`先于`open()`——task句柄不存在就先建session。`notifyCheckpointComplete`/`Aborted`对commit型sink透传。非RocksDB后端从store恢复native状态；RocksDB重新挂回活实例。

## 阶段8：close，按依赖逆序

先置`closing=true`（挡住排队中的回调），然后：解绑native回调（C++不再调Java）→关task（C++链销毁）→队列`noMoreInput`（状态置FINISHED让C++读到优雅结束——必须在关队列**之前**，否则C++对着已关闭的队列读）→关队列→注销session上下文→关session资源（分配器）→`super.close()`。每一步的存在都是为了让下一步不会和它赛跑。

## 新增场景：接入新的运行时算子

通常继承就够：继承`GlutenOneInputOperator`（或`GlutenTwoInputOperator`），传入planner侧造好的计划树，按想要的直通声明`RowData.class`或`StatefulRecord.class`——实际接线由JobGraph生成器的克隆决定。只在特殊生命周期时写子类（如WindowAggOperator在initializeState反射RocksDB句柄、文件sink自管提交）。覆写数据面方法时保持三段式：转Arrow→put→`processElementInternal`。新输入/输出类型扩展对应的桥工厂；不属于source/单输入/双输入三类的算子在`OffloadedJobGraphGenerator`加分支。

## 陷阱

| 症状 | 成因 | 规避 |
|---|---|---|
| 循环立刻退出、没有输出 | BLOCKED是"暂时没有"不是错误 | 等下次触发；数据到达与timer都会再驱动 |
| native内存增长 | 取回的`StatefulElement`没close | finally里close——它持有native句柄 |
| 双重free/Arrow缓冲区损坏 | 关了不属于自己的直通向量 | 谁分配谁释放；看node-id所有权判断 |
| timer或水位线的输出迟迟不来 | 旁路走完忘了拉输出 | 每个入口都以`processElementInternal`收尾 |
| 回调打在已关闭的算子上 | mailbox里的残留条目 | `closing`检查是承重的；覆写时保留 |
| C++读已关闭的队列 | 清理顺序错了 | `noMoreInput`严格在关队列之前 |
