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

覆盖一个Flink标量表达式在GFV栈上的端到端接入：velox侧C++实现（在flinksql命名空间下注册）、gluten planner映射、测试金字塔（velox C++单测、velox4j调用链单测、轻量e2e、全量双跑e2e）。不在范围内：状态算子、聚合函数、性能调优（归其他插件管）。

每个任务的铁律：

- 运行时路径注册在`velox/functions/flinksql/`下——spark/presto注册只作语义参考，绝不作为运行时实现。
- 表达式实现优先复用velox既有库/类（含既有函数实现——语义一致时经flinksql注册直接引用即可，无须重写）；复用不成立（无对应设施，或语义对照不一致）时才自写。
- 不允许修改既有表达式实现——行为、签名、结构一律不动；差异化语义只能扩展或新增（新重载、新注册条目、新文件），既有代码允许直接复用。

## Agent

| Agent | 职责 |
|---|---|
| stateless-expression-orchestrator | 阶段调度、门禁流转、用户门禁处暂停；从不亲自实现或评审 |
| stateless-expression-architect | 负责SPEC与DESIGN：velox调研、语义对照、flinksql注册设计、覆盖矩阵 |
| stateless-expression-developer | 负责实现：编码、构建、单测、轻量e2e自测 |
| stateless-expression-reviewer | 负责三道审计门禁：设计审计、代码审计、结果审计 |
| stateless-expression-verifier | 负责全量双跑e2e：SQL清单、changelog折叠对比、TEST_REPORT |

## 运行拓扑

主会话逐段推进工作流，一段=从当前状态推进到下一个停点（用户门禁、阻塞、全部完成）：

- 主会话前台调用orchestrator并等待返回；orchestrator对owner、reviewer同样只做前台Agent工具调用，禁止`run_in_background`——后台子任务随父代理返回即被回收，等于无声丢弃；禁止降级为OS子进程加轮询等待——僵尸进程会被`kill -0`误判存活。前台Agent调用不可用时立即返回上报，不用即兴替代方案续跑。
- 派发留痕：派发意图（交给谁、预期产物）先落`PROGRESS.md`一行再派发，恢复断点与静默判定都以它为据；orchestrator每次返回前把下一步动作写进`TASK_STATE.md`。
- orchestrator到停点即返回：用户门禁处带回决策点清单，阻塞处带回阻塞汇报，由主会话转呈用户；用户答复落`USER_GATES.md`后主会话再次唤起orchestrator续跑。orchestrator不在回合内等待用户答复。
- 唤起orchestrator的prompt带任务描述、目标项目根、本次推进目标；orchestrator被唤起先读`TASK_STATE.md`恢复。跨段连续性只由TASK_STATE.md与任务产物承载，不依赖Agent实例存续。
- 看门狗是主会话职责——orchestrator不运行时无人核查：主会话用定时任务每15~20分钟核查PROGRESS.md与TASK_STATE的更新时间，静默超阈值即上报用户并干预（问询或重派）；每条状态行以"下次核查约HH:MM"收尾，让静默边界可预期；隔夜等跨会话场景须用持久化定时或用户侧外部监控，会话级定时随会话关闭消失。

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
5. 排版与内容：遵守模板头部纪律——分点、单点一个事实+锚点、不超过两行、多裁决结论用裁决列表、不写散文段；只写核心方向与要点，agent的搜索/思考过程不写入。
6. 单测覆盖矩阵、e2e覆盖矩阵（每条e2e用例=一个SQL文件+固定输入）、特殊场景、风险。

门禁：reviewer产出DESIGN_AUDIT（审计报告模板，A节：方案合理性、逐条支撑性断言重核、覆盖完整性、排版与内容纪律）。裁决词表：通过/不通过——没有第三种；不通过必须给出具体审计意见；排版不达标（大段散文、要点无锚点）或含过程性叙述（agent搜索/思考步骤）同样不通过，返工仅限重排与删过程、不改结论要点。通过后才由用户门禁1放行实现。

### Implement

developer按已通过的设计编码：velox函数+flinksql注册+CMake+单测、velox4j调用链单测（EvaluationTest式harness、FLINK preset），gluten映射条目。构建部署只走flink-velox-build技能（绝不跳过C++构建）；单测只走flink-velox-unit-test；然后在GFV集群上做轻量e2e自测（自构造输入、print sink、验证脚本）。一切记录进IMPLEMENTATION.md，包括超出设计影响清单的改动（超范围改动是审计的致命发现项）。交付前按PR模板（`templates/pr.md`）备好PR.md：提交计划、PR描述、合入前检查单。

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

`tasks/<task-name>/`下的产物是跨Agent的唯一事实来源；口头结论不落产物即不存在。后序阶段读产物，不读聊天记录。

产物结构：有模板的产物（SPEC/DESIGN/IMPLEMENTATION/PR/TEST_REPORT/审计报告/upstream草稿）H1/H2标题集合与编号风格照对应模板逐字一致——不增、不删、不改名。owner落盘前结构自检；reviewer每道审计先做结构对照，不符=HIGH拦门，按"文档"归属返工（仅重排结构，不动技术内容）。

排版纪律（任务树全部产物适用，审计必检）：一个bullet只说一个事实，禁止用"；"串联第二个事实；表格单元格只放事实与锚点、不超过两行，推理过程移独立行；段落单行流动文本不硬换行。返工路由横向覆盖：某产物因问题X被退回时，orchestrator必须扫描同门禁全部呈报产物与任务树既有产物是否存在同类X，一并路由整改——只改被点名的一份不算完成。

```text
tasks/<task-name>/
  TASK_STATE.md                  跨Agent状态锚点
  USER_GATES.md                  用户门禁决策点与用户答复的逐轮追加记录
  PROGRESS.md                    阶段内进度心跳：owner逐里程碑追加一行（时间+agent+一句话）
  architect/    SPEC.md  DESIGN.md  SUMMARY.md
  developer/    IMPLEMENTATION.md  PR.md
  reviewer/     DESIGN_AUDIT.md  CODE_AUDIT.md  RESULT_AUDIT.md
  verifier/     TEST_REPORT.md
  upstream/     社区issue/PR草稿（按shared upstream-contribution模板，经用户确认后提交）

tmp/<task-name>/dispatch/        派发简报：每份派发落一份（owner、目标产物、必读锚点、纪律）
tmp/<task-name>/logs/            只放日志：cmd-outputs/  jobs/——不作门禁依据，随时可清理
```

e2e验证证据树在项目根`e2e/{sql,data,out,verify}/`，不在任务目录下——SQL表达验证范围、数据是固定输入、输出与对比是运行证据，跨任务沉淀为回归用例库；全量结果汇总在`e2e/verify/RESULTS.md`（每轮原地刷新），TEST_REPORT只引用其路径与结论。

TASK_STATE.md是唯一的恢复锚点：每次阶段流转与门禁裁决后更新。产物是快照：返工原地刷新既有文件，描述对象变了（代码回退重落、口径变更）须先刷新受影响产物再进下一门禁。

进度跟进：owner agent每到一个里程碑（读完关键参考、草拟完一节、跑完一轮构建）向`PROGRESS.md`追加一行：时间、agent、一句话——时间戳必须取`date +%F %T`实测输出，禁止估算，会话上下文携带的"当前时间"是陈旧快照，同样不可作判定依据。orchestrator派发时说明交给谁、预期产出什么，owner返回后立即汇报并更新TASK_STATE.md；owner返回而产物未落即派发失败，立即核查重派——回合内的进展核查是orchestrator职责，跨时段的静默看护是主会话职责（见运行拓扑）。用户随时`tail -f tasks/<task-name>/PROGRESS.md`感知进展。

构建/测试命令输出重定向进`tmp/<task-name>/logs/cmd-outputs/`，作业提交与崩溃现场进`tmp/<task-name>/logs/jobs/`；报告引用这些路径作为依据，但logs本身是临时产物——随时可清理，不裁决门禁。

## 用户门禁

| 门禁 | 位置 | 触发 |
|---|---|---|
| 1 | 设计审计通过后 | 写任何产品代码之前 |
| 2 | 代码审计通过后 | 交付/全量e2e开始之前 |
| 3 | 结果审计通过后 | 宣布任务完成之前 |

每个暂停处的呈报与确认按以下机制执行：

- **呈报四段**：①材料清单与阅读顺序（受审产物**全文**逐一列出——inline给出或给路径与阅读指引，"已提供全文"是放行前置自检项）；②决策点清单（见下）；③答复指引——用户只需逐条答"确认/异议＋意见"，格式整理由主会话承担；④禁止引用未呈报的清单编号。
- **决策点清单**：条目从受审产物及其模板章节抽取（如设计审计后：复用决策、映射选型、覆盖范围、风险接受），**范围外排除项与正向决策同等呈报义务**——每条排除带理由与依据来源。每条带四要素——决策内容（可判定的取值，"合理/适中"不算）、依据来源（产物哪一节）、归属（异议时退回哪个阶段）、确认/异议选项；只取产物已有内容，不向用户索要产物未定义的字段。
- **逐条交互**：决策点一次呈一条，用户答复后才呈下一条——禁止一次性全量倾倒，也禁止把多条合并成组降低确认摩擦；产物全文阅读与逐条确认解耦，用户说"看DESIGN"即单独呈全文。
- **落盘与放行**：用户答复逐条原文追加落`USER_GATES.md`；TASK_STATE门禁行记录呈报形态（全文/仅清单）备审计；全部确认才放行，有异议的条目按归属路由给owner Agent返工，受影响产物原地刷新、对应审计重跑。orchestrator不自己回答技术问题。

## 横切纪律

上下文节约：Agent只加载自己绑定的skills/docs；先grep再读。reviewer只指问题，不打补丁。审计二值（通过/不通过），不通过必须带意见；HIGH直接拦，MED/LOW是建议。changelog语义与对比标准按flink-velox-e2e-verify技能——verifier绝不放松“精确一致”。

Agent派发：每次派发都是全新实例；orchestrator在派发prompt里点名该owner本次要读与要写的产物，上下文恢复靠TASK_STATE.md与已有产物，不靠实例存续。
