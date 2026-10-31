# 有状态算子实现指南

新增有状态算子的实现契约：typed keyed state后端提供什么保证、算子要实现什么、状态管理如何交给后端。本文是spec与design阶段的主要技术参考；算子壳、事件模型与任务驱动见[internals/stateful-operator.md](internals/stateful-operator.md)。

## 总览

```text
gluten planner（Java）              velox native（C++）
──────────────────────             ─────────────────────────────────────────
影子ExecNode                        StatefulTask
  构造算子节点＋KeyedStateSpec       ├─ initializeState（params，records）
  包进StatefulPlanNode              │    ├─ task级StateBackend（Heap｜RocksDB）
  JSON跨JNI ───────────────►        │    ├─ 算子链initializeStateBackend
GlutenOneInputOperator             │    └─ restoreState → initializeState
（Flink侧保持非keyed）               StatefulOperator（keyed算子）
                                      ├─ initialize（）              无状态设施
                                      ├─ initializeStateBackend（）  建keyed后端
                                      ├─ addInput（StreamElement）   主流程
                                      └─ close（）
                                    HeapKeyedStateBackend<RowContainerStateKey>
                                      ├─ KeyTable：唯一key身份
                                      ├─ 句柄注册表（one name one state）
                                      └─ snapshot（）/restore（）：key-group分块
```

| 层 | 职责 |
|---|---|
| 计划（gluten＋velox4j） | 算子节点、`KeyedStateSpec`（key通道＋类型，纯计划数据）、serde镜像 |
| task（`StatefulTask`） | `KeyedStateBackendParameters`（maxParallelism与key-group子范围）、后端类型选择、checkpoint编排 |
| 算子（`StatefulOperator`子类） | 生命周期实现、业务逻辑、changelog语义、descriptor与回调 |
| 后端（`HeapKeyedStateBackend`） | key身份与探测、key-group分片、状态存取、物化回调、checkpoint读写、死key回收 |

## 后端契约

状态交给后端后，后端承担的保证：

| 保证 | 机制 |
|---|---|
| key身份唯一 | 后端构造时持有唯一KeyTable（key RowContainer＋hash表＋序列化器）；探测走`HashTable::groupProbe`，hash只做分桶，命中后逐列精确比较——碰撞的key不会并 |
| 分片稳定 | `keyGroup = hash % maxParallelism`；后端只管`[startKeyGroup, start+num)`子范围；maxParallelism全生命周期不变，rescale后边界不移动 |
| miss批物化 | 句柄`rows()`按批解析；miss的key一次物化新行并整批回调init——聚合初始化天然批式 |
| 恢复落位 | key反序列化经KeyTable恢复私门探测；恢复的key与运行时probe的key落在同一行同一桶 |
| 死key回收 | `advance()`只在批边界回收无引用的key行；snapshot前先回收，死key不过checkpoint |
| 同名同实例 | 句柄按名注册，二次获取返回同实例；同名异类型CHECK失败 |

key的呈现是`RowContainerStateKey`：key行指针视图＋构造时缓存的hash/keyGroup。key列类型支持定宽标量与varchar/varbinary；复杂类型需先归约为标量列。

## 状态句柄选型

| 句柄 | descriptor | 值形态 | 适用 |
|---|---|---|---|
| `AggregatingState<K,N>` | accumulators＋init/merge回调 | RowContainer行，accumulator布局（与HashAggregation行同构） | 聚合：函数原地更新slot |
| `ValueState<K,N,V>` | `TypeSerializer<V>` | 单值 | 每key标量（latest值、标记） |
| `ListState<K,N,T>` | `TypeSerializer<T>` | vector<T> | 每key追加序列 |
| `MapState<K,N,UK,UV>` | key/value序列化器 | map<UK,UV> | 每key子索引（join、rank） |

namespace类型`N`：无分区语义用`VoidNamespace`；同key多逻辑分区（窗口）用自定义`Namespace`。

Aggregating回调契约：

- `initRows(rows, numRows)`：miss批物化时整批调用，算子侧包装`Aggregate::initializeNewGroups`；
- `mergeRow(row, columns)`：恢复时把单行intermediate列合入新构行，算子侧包装`addSingleGroupIntermediateResults`；
- state层不依赖任何Aggregate设施——行构造与checkpoint往返全部经accumulators数组与两个回调；
- descriptor闭包捕获算子裸指针，被捕获对象的生命周期必须不短于句柄。

## 分步实现

### 1 计划节点（三仓镜像）

- velox：`StatefulPlanNode.h`加节点类（参照`GroupAggregationNode`：handler子节点＋`KeyedStateSpec`）；serialize/create/registerSerDe三件套。
- velox4j：`plan/`下同名同字段镜像类＋`stateful/KeyedStateSpec`；serde注册名与C++完全一致。
- `KeyedStateSpec`只含key通道与类型——运行期后端不在此层建：key-group范围只存在于task参数，算子的`initializeStateBackend`才建后端。

### 2 planner分派

`StatefulPlanner#transformStatefulOperators`按内层节点类型分派；新算子加一个分支：递归建targets→`EmptyOperator`占位→构造算子。纯流式算子没有batch算子本体，处理全在流式路径。

### 3 算子生命周期

| 钩子 | 职责 | 纪律 |
|---|---|---|
| 构造 | 持节点指针 | 计划约束钉成CHECK（输出schema、不支持的语义） |
| `initialize()` | 无状态设施（聚合函数经`makeAggregateInfos`） | 不碰state |
| `initializeStateBackend()` | 建keyed后端（下方五步） | keyed算子专属钩子 |
| `addInput()` | 主流程（下方七步范式） | 事件分派＋业务＋changelog |
| `close()` | reset句柄/后端/selector，再调基类 | 逆序释放 |

`initializeStateBackend`五步：

1. `createKeyedStateBackend<K>(*stateBackend, spec, memoryPool())`建后端——唯一创建入口，maxParallelism与key-group范围由入口内读task参数；
2. `KeySelector(backend->keyIndex(), spec.keyChannels())`绑定key表；
3. 构造descriptor，`getOrCreateXxxState<N>()`取句柄；
4. AggregatingState接线：`setAllocator`＋`setOffsets(valueRows->columnAt(i)…)`——必须早于首次`rows()`与restore（miss物化与恢复都建行）；
5. 调基类实现转发下游。

创建入口定义在`state/HeapKeyedStateBackend.h`，是自由模板函数：key类型K（StateKey子类）只有算子能命名，虚函数不能是模板，入口因此不能是`StateBackend`的虚成员——基类上的pre-generic工厂留给未迁移算子。入口按task后端声明类型分派：声明了无引擎的类型（当前ROCKSDB）在算子初始化期即`VELOX_UNSUPPORTED`fail loud，不静默回落heap。

`addInput`七步范式（`GroupAggregator`为范例）：

1. cast成`StreamRecord`并校验rowKind——不支持的kind必须fail loud，禁止静默丢弃；
2. `keySelector_->probe(input)`：一次probe得到每行key、distinctKeys与newGroups；
3. `state_->rows(distinctKeys, ns, outRows)`批解析状态行（miss触发init回调）；
4. 业务逻辑原地更新状态行（`addRawInput`等）；
5. changelog规划：新key发+I；值变发(-U＋)+U（-U仅当计划要求update-before）；未变不输出；
6. 组装`StreamRecord`（key列按发射索引从keyRowContainer提取，值列按kind选前后镜像）→`pushOutput`；
7. 批边界`keyedBackend_->advance()`。

水位线默认级联即可；仅事件时间算子（窗口类）需要覆写`processWatermark`。

### 4 gluten接线

- 影子覆盖Flink包名内的ExecNode：`translateToPlanInternal`构造velox4j节点树包进`StatefulPlanNode`，operator用`GlutenOneInputOperator`。
- 铁律：**Flink侧transformation保持非keyed**。key归velox所有（`KeyedStateSpec`喂C++后端），路由由C++ StreamPartition决定；声明Flink key selector会让runtime用Flink哈希重算key group并对照KeyGroupRange断言，与velox路由在并行度>1时冲突。

### 5 checkpoint

- 算子经`keyedStateBackend()`访问器暴露后端；快照与恢复的字节持久化由task侧checkpoint编排驱动。
- snapshot布局：header（maxParallelism、key-group范围、flags）→schema表（key schema＋每状态namespace/value schema）→按key group升序逐状态条目→CRC32尾。
- restore校验：CRC；maxParallelism必须相等（它定义key-group空间）；schema表与已注册状态逐一对照；流范围与本后端相交即收、范围外跳过——天然支持rescale分片恢复。
- 恢复顺序与Flink相反：先注册状态、后restore。句持有自己的表，restore直接分派给已注册句柄，无需backend级表注册处。

### 6 测试

参照`velox/experimental/stateful/tests/GroupAggregatorTest.cpp`：

- fixture：`OperatorTestBase`；注册所需聚合函数；`HashMapStateBackend`＋`KeyedStateBackendParameters`充当task级backend；
- 下游用收集型`StatefulOperator`；算子按生产生命周期顺序构造：`initialize()`→`initializeStateBackend()`；
- 输入三类：appendOnly（无rowKind列）、显式INSERT rowKind、混合kinds；
- 持久化：`snapshot()`→新算子`restore()`→继续喂数据断言等价；rescale用不同key-group范围恢复部分流；
- 后端设施单测见`StateBackendTest`（含创建入口分派）、`CheckpointFormatTest`、`StateKeyTest`、`KeySelectorTest`；checkpoint链路walk（无legacy handler也走全链）见`StatefulOperatorCheckpointTest`。

## 陷阱

| 症状 | 成因 | 规避 |
|---|---|---|
| 并行度>1时Flink断言key group不一致 | Flink侧transformation被声明成keyed | transformation保持非keyed |
| accumulator写坏或崩溃 | setAllocator/setOffsets晚于首次`rows()`或restore | 建句柄后立刻接线 |
| 句柄析构踩空 | descriptor闭包持算子裸指针，算子先亡 | close()先reset句柄；被捕获对象生命周期≥句柄 |
| `VELOX_NYI: … not available on the heap backend` | 走了旧状态API（基类工厂/`StreamOperatorStateHandler`） | 新算子一律用`HeapKeyedStateBackend`模板方法（typed API） |
| 初始化即`VELOX_UNSUPPORTED: The RocksDB keyed state backend is not implemented` | task后端声明了ROCKSDB，typed创建入口无该引擎 | 现行仅HEAP可用——后端声明不带未实现类型 |
| 恢复被拒：maxParallelism mismatch | maxParallelism改变即key-group空间改变 | 全生命周期固定 |
| 恢复被拒：schema或状态不匹配 | 状态未注册先恢复，或schema漂移 | 先注册后恢复；schema演进需版本化 |
| key列含array/map/row报错 | key相等性只支持定宽标量＋varchar/varbinary | key用标量列或先归约 |
| 死key行跨checkpoint | `advance()`未在批边界调用 | 每批末尾调用；snapshot前自动回收 |
