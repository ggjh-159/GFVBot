# DESIGN——<task-name>

> 按节填写；标注"无"的节保留标题。本方案通过设计评审（pass/fail）并经用户门禁1确认后方可进入实现。
> 排版纪律（评审项，不达标退回重排）：分点优先——每个要点一条bullet、只说一个事实、带源码锚点（`类#方法`＋仓库相对路径），单点不超过两行；不写连续散文段；含多个裁决的结论拆成裁决列表；表格单元格只放事实与锚点，不塞推理过程。
> 内容纪律（评审项）：只写核心方向与要点；agent的搜索、对比、思考过程不属于方案内容。
> 实现契约基准：`docs/gfvbot/shared/stateful-operator-implementation.md`——§3契约对照逐项过，该文档的陷阱表是§8风险的必查清单；引用其节名用原文（后端契约/状态句柄选型/分步实现/陷阱）。
> 不适用惯例：条目不适用写"不适用＋一行理由"，不删行不留空——复用型任务大量命中。

## 1. 任务与输入

| 项 | 内容 |
|---|---|
| 目标算子 | `<算子名>`（Flink语义对应`<StreamExecXxx>`） |
| SPEC | `tasks/<task-name>/architect/SPEC.md` |
| 实现契约 | `docs/gfvbot/shared/stateful-operator-implementation.md` |
| 参照算子 | `GroupAggregator`（`velox/experimental/stateful/agg/`） |

## 2. 现状调研

| 项 | 结论 | 证据（路径） |
|---|---|---|
| planner分派现状 | `StatefulPlanner#transformStatefulOperators`是否已有同类分支 | `velox/experimental/stateful/StatefulPlanner.cpp` |
| 计划节点现状 | `StatefulPlanNode.h`中可参照的节点类 | 同上目录 |
| gluten ExecNode现状 | 是否已有影子覆盖类 | `gluten-flink/planner/.../stream/` |
| 既有可复用设施 | <算子壳/KeySelector/句柄/序列化器> | |
| 语义差距 | <Flink语义与velox现状的差距一句话> | |

## 3. 契约对照（逐项过实现契约文档）

### 3.1 状态句柄选型

| 项 | 取值 | 依据（契约文档§状态句柄选型） |
|---|---|---|
| 句柄 | <Aggregating/Value/List/Map>State | |
| namespace | <VoidNamespace/自定义Namespace> | |
| 值形态 | <RowContainer行/单值/vector/map> | |

### 3.2 生命周期范式落位

- `initialize()`建的无状态设施：<如聚合函数经makeAggregateInfos>
- `initializeStateBackend()`六步落位：<每步对应到本算子的具体对象>
- `addInput()`七步落位：<每步对应到本算子的具体动作，changelog规划写明+I/-U/+U触发条件>
- 铁律对照：Flink侧transformation保持**非keyed**；状态一律走`HeapKeyedStateBackend`typed API（不走基类工厂/`StreamOperatorStateHandler`旧平面）。

### 3.3 计划与分派

- 计划节点：velox节点类`<XxxNode>`（`StatefulPlanNode.h`）＋velox4j镜像类＋serde注册名`<完全一致的名>`
- `KeyedStateSpec`：key通道`<channels>`＋key类型`<types>`
- planner分派：`transformXxxOperator`分支要点
- gluten接线：影子覆盖`<StreamExecXxx>`，operator用`GlutenOneInputOperator`

## 4. 受影响模块与文件

| 仓 | 文件 | 改动 |
|---|---|---|
| velox | `velox/experimental/stateful/StatefulPlanNode.h` | 新增节点类＋serde三件套 |
| velox | `velox/experimental/stateful/StatefulPlanner.cpp` | 分派分支 |
| velox | `velox/experimental/stateful/<目录>/<Operator>.h/.cpp` | 新增算子 |
| velox | `velox/experimental/stateful/tests/<Test>.cpp` | 单测 |
| velox4j | `plan/<Node>.java`＋`stateful/KeyedStateSpec` | 镜像类 |
| gluten | `planner/.../StreamExec<Xxx>.java` | 影子覆盖 |

## 5. 执行与数据流

- 输入→probe→状态解析→业务→changelog→输出的每步落点：<按七步范式逐条，带锚点>
- watermark处理：<默认级联/覆写`processWatermark`的理由>
- 批边界动作：<`advance()`回收时机>

## 6. checkpoint语义

- 状态条目与schema：<每句柄的value schema>
- 恢复约束：<maxParallelism固定、先注册后恢复的落位>

## 7. 测试策略

### 7.1 单元测试矩阵（参照`GroupAggregatorTest`fixture）

| 用例 | 输入 | 期望 | 覆盖意图 |
|---|---|---|---|
| appendOnly | | | 无rowKind列 |
| 显式INSERT | | | rowKind校验 |
| 混合kinds | | | <支持的kind组合> |
| changelog断言 | | | +I/-U/+U触发与抑制 |
| snapshot/restore往返 | | | 恢复后继续喂数等价 |
| rescale恢复 | | | 部分key-group范围 |

### 7.2 e2e

| 用例 | SQL/查询 | 输入构造 | 对比基线 |
|---|---|---|---|
| | <nexmark qNN或自构造SQL> | | <原生Flink输出/changelog还原比对> |

## 8. 风险（契约陷阱表逐项核对，行数与契约表一致）

| 陷阱（契约文档§陷阱） | 是否适用 | 规避落点 |
|---|---|---|
| Flink侧被声明keyed | | transformation非keyed |
| setAllocator/setOffsets接线时机 | | |
| descriptor闭包生命周期 | | close()逆序reset |
| 误用旧状态API | | typed API |
| maxParallelism漂移 | | 全生命周期固定 |
| schema漂移/先注册后恢复 | | |
| key列含复杂类型 | | |
| 死key跨checkpoint | | 批边界advance |

## 9. 对SPEC的偏差

<无/逐条：偏差内容＋原因＋是否需回写SPEC>
