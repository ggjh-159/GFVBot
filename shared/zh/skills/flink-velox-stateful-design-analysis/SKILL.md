---
name: flink-velox-stateful-design-analysis
description: stateful算子DESIGN机制级分析程序——以已批准SPEC为合约，产出翻译链诚实分级、复用处置枚举、公式定位、对齐清单、限制清单与待裁决项等各节素材，每条结论一句依据。
---

# flink-velox-stateful-design-analysis

## 用途

design阶段architect的机制级分析程序：以已批准的SPEC为合约，把"怎么做"的分析做实，产出DESIGN.md各节的带锚点素材。可行性判定与验收口径在spec阶段已经钉死（flink-velox-stateful-spec-analysis），本技能不重复spec侧分析；DESIGN.md的落笔与取舍归architect。

## 输入契约

必需：`tasks/<task-name>/architect/SPEC.md`（已过SPEC评审）。可用：`docs/gfvbot/shared/stateful-operator-implementation.md`（实现契约，主技术参考）、reviewer反馈（返工轮）。检索一律组合调用flink-velox-docs-search（范围限定、相关度评估、上下文节约规则全部沿用），本技能不自行在线检索。

## 分析纪律

- 每条结论一句依据：源码出处、先例或裁决日期；不接受无依据断言。
- 现状核实不推断："已存在/零改动"类声明必须在源码核实后才能写，附file:line。
- 复用处置枚举：每项设施给处置（直接复用/改造复用/新建/不采用）；不采用也要写附理由，避免后来者重复考察。
- 非默认路径机制完整：EMIT等非默认配置路径给完整机制（元数据来源、发射判定、状态附加件），不许只写"暂不支持"。
- 机制偏离Flink同构的选择（换存储/换通道/换索引）升格为待裁决项，不静默自定。
- 状态选型照Flink原生：Flink用keyed state的算子这里就用keyed state（`HeapKeyedStateBackend` typed API＋对应句柄）；operator state只用于Flink原生就用operator state的场景——以实现简便为由的替代不接受，偏离升格为待裁决项并附Flink源码依据。
- 修改边界：受影响文件与复用处置只落在工作流范围节允许的文件（计划翻译、节点新增类与serde注册、planner分派分支、算子实现文件、单测、velox4j镜像类、gluten影子覆盖）；框架核心（算子基类、状态后端与句柄实现、RowContainer、serde基础设施、通用工具）只读，能力缺口写成待裁决项而非框架改动。

## 流程

### 第1步——机制级语义深化

从Flink源码提炼目标算子的机制事实，作为§5对齐清单的种子：

- 选型表：输入形态/算子变体→处理器/状态形态→触发方式。
- 数据流三流：record/watermark/timer路径（processElement→状态；processWatermark→fire→传播）。
- changelog判定链：哪个标志决定updating流＋场景表（场景/触发/RowKind/状态动作）。
- 关键行为要点清单：逐条带file:line——迟到判定、时区、空窗、输出先于watermark传播等；条目要与SPEC行为规格对得上。
- 原生状态设计：定位Flink对应算子的实现类及其状态声明——`ValueState`/`MapState`/`ListState`/`AggregatingState`/`ReducingState`、keyed还是operator state、descriptor与命名——带file:line；这是§3.1状态句柄选型的基准，也是对齐清单的必对齐项。两类state的区别以Flink官方文档为基准出处（https://nightlies.apache.org/flink/flink-docs-stable/docs/dev/datastream/fault-tolerance/state/ ）：Keyed State随key分区、按key-group恢复与rescale；Operator State绑定算子并行实例、只按list/union重分发——按key维护状态的算子用Operator State是选型错误。

### 第2步——GFV现状三段核实

翻译链三段逐一核实，诚实分级（齐全/半成品/缺位；半成品＝死代码/硬编码/NYI，逐个file:line举证）：

- gluten遮蔽翻译：`StatefulPlanner#transformStatefulOperators`是否已有同类分支、ExecNode影子覆盖现状。
- velox4j bean＋C++ serde：`StatefulPlanNode.h`既有节点类与serde三件套。
- C++算子：`experimental/stateful`现状、`GroupAggregator`样板可借鉴面。

### 第3步——复用处置与公式定位

- 复用处置枚举：算子壳/KeySelector/状态句柄/序列化器逐项给处置与说明——落§2。
- 公式定位：新算子＝`GroupAggregator`骨架＋增量维度，一句话说清增量集中在哪——落§1。
- 契约对照落位：状态句柄选型（以第1步的原生状态设计为基准，Flink用keyed这里就用keyed）、initializeStateBackend五步、addInput七步逐项对应到本算子——落§3。

### 第4步——执行流与对齐清单

- 七步范式落点：输入→probe→状态解析→业务→changelog→输出逐条带锚点——落§5。
- 对齐清单：第1步行为要点逐条对照（Flink行为＋本设计处理＋对齐度）；对齐度用词＝精确（同公式同机制）/等价（机制不同语义同，须给等价性论证）/一致（与既有裁剪口径同款）/分阶段（机制在设计内、实现留末阶段）/裁剪（必须带裁决依据）。
- 非默认路径单列，机制完整——落§5/§6。

### 第5步——限制、待裁决与测试面

- 限制清单：fail loud排除项逐条编号，TODO写待解决的能力归属——限制是待解决问题，不是终态语义——落§9。
- 待裁决项：只收机制偏离Flink同构或影响合约口径级别的选择；逐项背景自含＋方案对比表（维度×方案）＋建议＋一句依据——落§10。
- nexmark触达面：哪些查询落在本算子、可作e2e基线的既有套件——落§7。

## 输出契约

素材按DESIGN模板节组织、每条事实带锚点（`路径#类/方法`或`path:line`），结论注明依据来源（源码/先例/裁决日期）。查证不到的要点明说"未查到"，不用相邻内容推断。素材只呈给architect整理进DESIGN.md，本技能不落盘、不写DESIGN；待裁决项由architect落§10，经用户门禁1逐条裁决后原地回填。
