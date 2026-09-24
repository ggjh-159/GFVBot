---
name: flink-velox-code-review
description: GFV代码变更的结构化评审——层次边界、资源管理、异常处理、序列化兼容、内存安全与常见反模式，由变更面分析与固定检查清单驱动。
---

# flink-velox-code-review

## 核心原则

1. 只看diff——只评审改动；未改动的基线默认不在范围内。
2. 变更驱动——变更面标签决定哪些检查维度适用；不撒网。
3. 清单驱动——走固定检查清单；自由探索是次要的。
4. 格式先行——机器可查的格式问题最先出局，不占人工评审注意力。
5. 输出约束——每个问题一行，带`file:line`；评审输出绝不出现代码块或修复建议。

## 流程

### 第0步——格式基线

改动文件先过机器格式检查，格式不过不进入深审：

- C++改动（velox仓、gluten仓`cpp/`）：按仓根`.clang-format`跑`clang-format --dry-run --Werror <改动文件>`；gluten仓的CI等价入口是`dev/check.py format`。
- Java改动（velox4j、gluten-flink）：核对基础格式一致性——import顺序、行尾空白、tab混用；所在仓配有格式工具链（spotless等）时跑仓内入口。
- 格式问题按问题清单列出（严重级HIGH）；修格式不改变变更面标签。

### 第1步——变更面分析

输入：diff（优先`git diff`输出），或带行号区间的改动文件清单。跑`scripts/diff-parser.sh`（或按其规则手工打标）得到文件清单、语言与变更标签。标签集合：`arrow-res`、`exception`、`json-serde`、`rexcall`、`operator`、`pointer`、`numeric`、`import`、`api-change`、`other`。

### 第2步——脚本检查

标签命中处跑静态脚本：

- `scripts/layer-dep-check.sh <workspace-root>`——层次边界违规（planner导入runtime内部、runtime导入planner类、velox4j公开API泄漏内部实现）。在`<workspace-root>/repos/`下自动发现模块路径。
- `scripts/anti-pattern-grep.sh <workspace-root> [changed-files]`——grep级反模式：空catch块、try-with-resources之外的Arrow vector、processElement里的分配、魔法数字、未初始化的C++变量。

脚本发现是线索不是结论：逐条对照diff核实后再上报。

### 第3步——走检查清单

按节顺序走checklist.md，只执行标签触发的节。每项产出`- [ ]`（未发现问题）或`- [x]`（有问题，带`file:line`）。

## 输入契约

必需：以diff形式给出的代码变更，或带区间的改动文件清单；仅在被明确要求时才全文件模式。可选：SPEC/设计影响清单与任务的允许改动范围——提供时，范围合规检查为必做，超范围改动是致命fail。

## 输出契约

每个问题一行：`severity——file:line——问题描述`。严重级：CRITICAL（评审结论变fail）、HIGH、MEDIUM、LOW。结尾给结论（`pass`/`pass with suggestions`/`fail`）与各级计数。不写代码块、不给补丁草图、不复述未改动的代码。
