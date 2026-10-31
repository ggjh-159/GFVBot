# DESIGN——<task-name>

> 按节填写；标注"无"的节保留标题。本方案通过设计评审（pass/fail）并经用户门禁1确认后方可进入实现。
> 排版纪律（评审项，不达标退回重排）：分点优先——每个要点一条bullet、只说一个事实、带源码锚点（`类#方法`＋仓库相对路径），单点不超过两行；不写连续散文段；含多个裁决的结论拆成裁决列表；表格单元格只放事实与锚点，不塞推理过程。
> 内容纪律（评审项）：只写核心方向与要点；agent的搜索、对比、思考过程不属于方案内容。
> 依据纪律（评审项）：每条结论带一句依据（源码出处/裁决日期/先例）；"已存在/零改动"类现状声明必须源码核实。
> 实现契约基准：`docs/gfvbot/shared/stateful-operator-implementation.md`——§3契约对照逐项过，该文档的陷阱表是§8风险的必查清单；引用其节名用原文（后端契约/状态句柄选型/分步实现/陷阱）。
> 不适用惯例：条目不适用写"不适用＋一行理由"，不删行不留空——复用型任务大量命中。

## 1. 任务与输入

| 项 | 内容 |
|---|---|
| 目标算子 | `<算子名>`（Flink语义对应`<StreamExecXxx>`） |
| 公式 | <新算子>＝`GroupAggregator`骨架＋<增量维度一句话> |
| SPEC | `tasks/<task-name>/architect/SPEC.md` |
| 实现契约 | `docs/gfvbot/shared/stateful-operator-implementation.md` |
| 参照算子 | `GroupAggregator`（`velox/experimental/stateful/agg/`） |

## 2. 现状调研

翻译链三段诚实分级——半成品（死代码/硬编码/NYI）逐个file:line举证；"已存在/零改动"声明必须源码核实后才能写：

| 段 | 分级（齐全/半成品/缺位） | 证据（路径:行号） |
|---|---|---|
| gluten遮蔽翻译（`StatefulPlanner#transformStatefulOperators`分派链与ExecNode影子覆盖现状） | | `gluten-flink/planner/.../stream/`、`velox/experimental/stateful/StatefulPlanner.cpp` |
| velox4j bean＋C++ serde（`StatefulPlanNode.h`既有节点类） | | `velox/experimental/stateful/` |
| C++算子（`experimental/stateful`现状） | | |

复用处置枚举——每项给处置；不采用的设施也列出附理由，避免后来者重复考察：

| 设施 | 处置（直接复用/改造复用/新建/不采用） | 说明（改造点或否决理由） |
|---|---|---|
| <算子壳/KeySelector/句柄/序列化器/...> | | |

语义差距：<Flink语义与velox现状的差距一句话>

## 3. 契约对照（逐项过实现契约文档）

### 3.1 状态句柄选型

| 项 | 取值 | 依据（契约文档§状态句柄选型） |
|---|---|---|
| 句柄 | <Aggregating/Value/List/Map>State | |
| namespace | <VoidNamespace/自定义Namespace> | |
| 值形态 | <RowContainer行/单值/vector/map> | |

### 3.2 生命周期范式落位

- `initialize()`建的无状态设施：<如聚合函数经makeAggregateInfos>
- `initializeStateBackend()`五步落位：<每步对应到本算子的具体对象，第一步固定走createKeyedStateBackend创建入口>
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
- 对齐清单：行为要点逐条对照——Flink行为（file:line）＋本设计处理＋对齐度（精确/等价/一致/分阶段/裁剪）；等价须给等价性论证，裁剪必须带裁决依据
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

## 9. 限制清单

| 编号 | 限制 | TODO（待解决的能力归属） |
|---|---|---|
| L1 | <fail loud排除项——是待解决问题，不是终态语义> | <能力归属> |

实现时fail loud处一律带TODO注释，编号对应本表。

## 10. 待裁决项

<无——或逐项：背景（自含，含Flink侧机制与本栈现状的锚点）＋方案对比表（维度×方案，建议列标"建议"）＋建议＋一句依据>

只收机制偏离Flink同构或影响合约口径级别的选择；违背SPEC合约的机制选择不得静默自定。裁决经用户门禁1逐条进行；已裁决项标注日期与结论并同步进契约对照各表的依据列，合约级变化回填SPEC并注明日期、偏差记§11。

## 11. 对SPEC的偏差

<无/逐条：偏差内容＋原因＋是否需回写SPEC>
