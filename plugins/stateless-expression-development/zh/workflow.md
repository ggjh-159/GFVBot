---
scheduler: stateless-expression-orchestrator
stages:
  - name: spec
    owner: stateless-expression-architect
  - name: design
    owner: stateless-expression-architect
  - name: implement
    owner: stateless-expression-developer
  - name: verify
    owner: stateless-expression-verifier
  - name: retro
    owner: stateless-expression-architect
---

# 无状态表达式开发工作流

## 范围

覆盖一个Flink标量表达式在GFV栈上的端到端接入：velox侧C++实现（在flinksql命名空间下注册）、gluten planner映射、测试金字塔（单测、轻量e2e、全量双跑e2e）。不在范围内：状态算子、聚合函数、性能调优（归其他插件管）。

每个任务的铁律：运行时路径注册在`velox/functions/flinksql/`下——spark/presto注册只作语义参考，绝不作为运行时实现。

## Agent

| Agent | 职责 |
|---|---|
| stateless-expression-orchestrator | 阶段调度、门禁流转、用户门禁处暂停；从不亲自实现或评审 |
| stateless-expression-architect | 负责SPEC与DESIGN：velox调研、语义对照、flinksql注册设计、覆盖矩阵 |
| stateless-expression-developer | 负责实现：编码、构建、单测、轻量e2e自测 |
| stateless-expression-reviewer | 负责三道审计门禁：设计审计、代码审计、结果审计 |
| stateless-expression-verifier | 负责全量双跑e2e：SQL清单、changelog折叠对比、TEST_REPORT |

## 前置条件

环境就绪（仓库克隆、工具链安装、集群构建）是CLI的事，不是Agent阶段：`gfvbot env`、`gfvbot env-init`、`gfvbot clone`，再由flink-velox-build技能部署jars、启动集群。工作流假定已有一套可用的GFV集群和一套用于双跑的原生Flink集群。

## 阶段模型

| 阶段 | owner | 门禁 | 关键产物 |
|---|---|---|---|
| spec | architect | — | SPEC.md |
| design | architect | 设计审计通过+用户门禁1 | DESIGN.md |
| implement | developer | 代码审计通过+用户门禁2 | IMPLEMENTATION.md、PR.md |
| verify | verifier | 结果审计通过+用户门禁3 | TEST_REPORT.md |
| retro | architect | — | SUMMARY.md、upstream/草稿（涉及时） |

## 阶段细节

### Spec

architect按SPEC模板（`templates/spec.md`）填写：任务信息、语义基线钉在`docs/gfvbot/shared/flink-expressions/`下该函数的卡片上（签名、返回类型、NULL行为、边界行为——卡片是唯一事实来源）、目标与范围、验收标准、验证计划。SPEC刻意保持小；这里的含糊会毒化下游一切。

### Design

architect按DESIGN模板（`templates/design.md`）填写。必做动作：

1. velox调研：读卡片的“velox实现”节，再到velox源码核实（注册名、实现文件）。逐选项给结论：直接参考复用、迁移进flinksql、重写（语义不匹配）、新实现。
2. 语义对照表：NULL处理、空输入、越界/非法入参、类型矩阵、返回精度、函数特有维度——任一不匹配即禁止直接复用。
3. flinksql注册设计（名称、文件、注册方式、显式签名、CMake），按flink-velox-flinksql-registration技能执行。
4. gluten映射设计（RexCallConverterFactory条目；自定义converter还是直接名称映射）。
5. 单测覆盖矩阵、e2e覆盖矩阵（每条e2e用例=一个SQL文件+固定输入）、特殊场景、风险。

门禁：reviewer产出DESIGN_AUDIT（审计报告模板，A节：方案合理性、逐条支撑性断言重核、覆盖完整性）。裁决词表：通过/不通过——没有第三种；不通过必须给出具体审计意见。通过后才由用户门禁1放行实现。

### Implement

developer按已通过的设计编码：velox函数+flinksql注册+CMake+单测，gluten映射条目。构建部署只走flink-velox-build技能（绝不跳过C++构建）；单测只走flink-velox-unit-test；然后在GFV集群上做轻量e2e自测（自构造输入、print sink、验证脚本）。一切记录进IMPLEMENTATION.md，包括超出设计影响清单的改动（超范围改动是审计的致命发现项）。

门禁：reviewer产出CODE_AUDIT（B节：与设计一致性、文档与实现同步、安全性、单测对设计矩阵的完整性、代码格式、更简/更优写法、冗余/可扩展性/可读性）。通过+用户门禁2放行交付。

### Verify

verifier从设计的e2e矩阵构建全量SQL清单：固定文件系统输入、print sink、每用例一个SQL。每条用例在原生Flink与GlutenFlink上各跑一遍，输出按changelog（+I/-U/+U/-D）折叠回最终结果集后精确对比——不允许多行、少行、字段不一致；作业只有到FINISHED才算通过。回归：已映射表达式的代表性用例必须保持一致。用例与证据落项目根`e2e/`证据树、全量结果汇总落`e2e/verify/RESULTS.md`，TEST_REPORT.md引用其路径与结论——全部按flink-velox-e2e-verify技能执行。

门禁：reviewer产出RESULT_AUDIT（C节：单测全过、测试范围对设计矩阵、e2e结果与回归）。通过+用户门禁3关单。

### Retro

改动涉及velox/velox4j/gluten仓库时，developer按`docs/gfvbot/shared/templates/upstream-contribution/`的路由规则备社区草稿：每个被改仓库一份PR草稿、每个表达式至多一个issue草稿（改gluten仓用gluten模板，否则用velox/velox4j模板），落`upstream/`，经用户最终确认后才实际提交——Agent绝不自动提issue或PR。

architect归档：SUMMARY.md（交付了什么、与设计的偏差、遗留问题、经验教训是否值得沉淀进插件skills/docs——值得的给出沉淀建议）、TASK_STATE.md更新为关闭。

## 允许的回退与禁止的跳步

允许：审计不通过→返工目标产物→重审。产物是快照：返工直接**原地刷新**既有文件（`DESIGN.md`、`DESIGN_AUDIT.md`），不加版本序号、不留旧版文件；轮次历史由TASK_STATE门禁记录每轮追加一行承载。验证失败定位到实现→回到implement（TASK_STATE记一笔）；定位到设计→回到design。

禁止：设计审计未通过就动手实现；代码审计未通过就跑全量e2e；任一审计未通过或任一用户门禁被跳过就宣布完成；把“编译通过”当“验证通过”。

## 产物契约

按任务组织、跨Agent共享与临时分层（框架运行时产物布局）：

```
tmp/<task-name>/
  TASK_STATE.md                  跨Agent状态锚点
  USER_GATES.md                  用户门禁决策点与用户答复的逐轮追加记录
  architect/    SPEC.md  DESIGN.md  SUMMARY.md
  developer/    IMPLEMENTATION.md  PR.md
  reviewer/     DESIGN_AUDIT.md  CODE_AUDIT.md  RESULT_AUDIT.md
  verifier/     TEST_REPORT.md
  upstream/     社区issue/PR草稿（按shared upstream-contribution模板，经用户确认后提交）
  logs/                          临时产物：cmd-outputs/  jobs/——不作门禁依据，随时可清理
```

e2e验证证据树在项目根`e2e/{sql,data,out,verify}/`，不在tmp下——SQL表达验证范围、数据是固定输入、输出与对比是运行证据，跨任务沉淀为回归用例库；全量结果汇总在`e2e/verify/RESULTS.md`（每轮原地刷新），TEST_REPORT只引用其路径与结论。

口头结论不落产物即不存在。TASK_STATE.md是唯一的恢复锚点：每次阶段流转与门禁裁决后更新。产物是快照：返工原地刷新既有文件，描述对象变了（代码回退重落、口径变更）须先刷新受影响产物再进下一门禁。构建/测试命令输出重定向进`logs/cmd-outputs/`，作业提交与崩溃现场进`logs/jobs/`；报告引用这些路径作为依据，但logs本身不裁决门禁。

## 用户门禁

| 门禁 | 位置 | 触发 |
|---|---|---|
| 1 | 设计审计通过后 | 写任何产品代码之前 |
| 2 | 代码审计通过后 | 交付/全量e2e开始之前 |
| 3 | 结果审计通过后 | 宣布任务完成之前 |

每道用户门禁的执行方式：orchestrator把受审报告连同**关键决策点清单**呈给用户逐条确认。清单条目从受审产物及其模板章节抽取（如设计审计后：复用决策、映射选型、覆盖范围、风险接受），每条带四要素——决策内容（可判定的取值，"合理/适中"不算）、依据来源（产物哪一节）、归属（异议时退回哪个阶段）、确认/异议选项；只取产物已有内容，不向用户索要产物未定义的字段。用户答复逐条原文追加落`USER_GATES.md`；全部确认才放行，有异议的条目按归属路由返工，受影响产物原地刷新、对应审计重跑。

## 横切纪律

上下文节约：Agent只加载自己绑定的skills/docs；先grep再读。reviewer只指问题，不打补丁。审计二值（通过/不通过），不通过必须带意见；HIGH直接拦，MED/LOW是建议。changelog语义与对比标准按flink-velox-e2e-verify技能——verifier绝不放松“精确一致”。
