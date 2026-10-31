---
name: flink-velox-stateful-spec-analysis
description: stateful算子SPEC可行性分析程序——语义映射×设施供给双维定档、查矩阵得四选一结论、约束只升不降且逐条记录，产出按SPEC模板节组织的带锚点素材。
---

# flink-velox-stateful-spec-analysis

## 用途

spec阶段architect的可行性分析程序：从任务描述出发判定目标算子在GFV栈上是否可行、以何种结论可行，并为SPEC各节收集带锚点的事实素材。本技能产出素材与结论；SPEC.md的落笔与取舍归architect。

## 输入契约

必需：任务描述（目标算子名＋期望语义）。可用：用户约束、`tasks/<task-name>/TASK_STATE.md`。检索一律组合调用flink-velox-docs-search（范围限定、相关度评估、上下文节约规则全部沿用），本技能不自行在线检索。

## 判定维度

**A——语义映射**（Flink算子语义→velox现状，逐行为要点查证）：

| 档位 | 含义 |
|---|---|
| A1精确匹配 | velox已有同语义设施，直接可用 |
| A2部分匹配·栈内可补偿 | 语义有差距，本栈内可补偿（如keyed语义经非keyed transformation＋KeySelector） |
| A3需上游能力 | 差距补齐依赖上游仓（velox核心、Flink发行版、社区） |
| A4无支撑 | 语义在本栈无实现路径 |

**B——设施供给**（栈边界内既有设施清点）：

| 档位 | 含义 |
|---|---|
| B1直接复用 | 状态句柄、算子壳、serde、plan镜像全部既有 |
| B2扩展点新增 | 在既有扩展点内新增（StatefulPlanNode.h节点类、planner分派分支、gluten影子覆盖） |
| B3框架机制改动 | 需改框架本体（StatefulTask、StatefulOperator壳、状态后端机制） |

**栈边界**：本栈＝velox/experimental/stateful＋velox/functions/flinksql＋velox4j整个仓＋gluten-flink模块；其余（velox核心、gluten非flink部分、Flink发行版、待社区合入）都是上游。

**结论矩阵**（行A×列B，查表即结论）：

| A\B | B1 | B2 | B3 |
|---|---|---|---|
| A1 | feasible | feasible | feasible with constraints |
| A2 | feasible with constraints | feasible with constraints | feasible with constraints |
| A3 | feasible with upstream dependency | feasible with upstream dependency | feasible with upstream dependency |
| A4 | not feasible | not feasible | not feasible |

## 调节规则

1. 矩阵格子是下限，约束只升不降：矩阵结论只反映语义与设施两维；查证中发现任务级硬约束（如仅支持appendOnly源、状态规模上限）时结论上调一档（feasible→feasible with constraints）。只许往严调，不许以“实现难”自降。
2. 伴随约束无论档位逐条记录：结论落在任何档位，伴随约束逐条写进可行性素材的约束清单——不因“已是最严档”省略（upstream dependency结论下，等待期间的堆内存上限仍是有效约束）。

## 流程

### 第1步——语义查证，定A档

- 对照Flink语义锚点（`StreamExecXxx`＋Flink 1.19文档）列目标算子行为要点：触发与节奏、状态访问、watermark/timer、输出与changelog。
- 逐要点查velox现状：docs-search定位`stateful-operator-implementation.md`与`internals/stateful-operator.md`，再进repos/velox源码取锚点。
- 每要点一行：要点——现状——锚点；据此定A档并注明定档依据。

### 第2步——设施查证，定B档

- 按栈边界清点四区设施：状态句柄（`state/HeapKeyedStateBackend.h`）、算子壳与样板（`StatefulOperator.h`、`agg/GroupAggregator`）、计划节点与serde（`StatefulPlanNode.h`）、Java镜像与gluten接线（velox4j的`plan/`、gluten-flink的planner）。
- 每区一行：设施——复用/扩展/改框架——锚点；据此定B档。

### 第3步——查矩阵定结论

- A×B查结论矩阵得结论。
- 应用调节规则1：任务级硬约束升档。
- 应用调节规则2：汇总伴随约束清单，逐条带证据锚点。

### 第4步——其余节素材

可行性节素材已由第1~3步产出；为SPEC其余节收集带锚点事实：

- 目标与范围：目标一句话由任务愿望经第1步语义要点压缩；范围内取第2步将触达的设施层次；范围外每条排除给理由＋依据锚点（指向A档差距或约束清单）——排除项不许无据排除。
- 接口规格：输入输出类型、值形态（RowContainer行/单值）、serde注册名候选——锚点取既有同类算子。
- 行为规格：生命周期五步/七步在本算子的落位雏形、watermark默认级联——锚点取契约文档与GroupAggregator样板。
- 验收标准与验证计划：可作基线的既有套件（GroupAggregatorTest、nexmark用例、e2e双端比对）——锚点取测试文件与用例库。
- 任务节（task-name/日期/来源）是派发元数据，architect照实转写，本技能不产出。

## 输出契约

素材按SPEC模板节组织，每条事实带锚点（`路径#类/方法`或`path:line`）；结论行注明矩阵档位（如`feasible with constraints（A2×B1）`）。查证不到的要点明说“未查到”，不用相邻内容推断。素材只呈给architect整理进SPEC.md，本技能不落盘、不写SPEC。
