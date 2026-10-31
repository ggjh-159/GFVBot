---
scheduler: stateful-operator-orchestrator
stages:
  - name: spec
    owner: stateful-operator-architect
  - name: design
    owner: stateful-operator-architect
  - name: implement
    owner: stateful-operator-developer
  - name: verify
    owner: stateful-operator-verifier
  - name: retro
    owner: stateful-operator-architect
---

# 有状态算子开发工作流

## 范围

本工作流管辖GFV栈上有状态算子的开发：

- gluten-flink planner：把Flink计划与表达式翻译成velox计划（有状态算子）
- gluten-flink runtime：算子执行、状态访问、水位线处理、数据桥接
- velox experimental stateful：C++有状态算子框架、状态存储、按key执行
- velox4j：跨语言边界承载有状态语义的Java/JNI桥

大规模velox上游同步不在范围内，除非用户明确授权并单列验证边界。

## Agent

| Agent | 职责 |
|---|---|
| stateful-operator-orchestrator | 阶段调度、门禁执行、用户门禁暂停、分歧仲裁；从不亲自实现 |
| stateful-operator-architect | 负责SPEC、设计与最终总结 |
| stateful-operator-developer | 负责实现、自验证与PR准备 |
| stateful-operator-reviewer | 负责全部评审门禁：SPEC评审、设计评审、代码评审、最终验收 |
| stateful-operator-verifier | 负责验证：单测、端到端运行、回归检查 |

## 运行拓扑

主会话逐段推进工作流，一段=从当前状态推进到下一个停点（用户门禁、阻塞、全部完成）：

- 主会话前台调用orchestrator并等待返回；orchestrator对owner、reviewer同样只做前台Agent工具调用，禁止`run_in_background`——后台子任务随父代理返回即被回收，等于无声丢弃；禁止降级为OS子进程加轮询等待——僵尸进程会被`kill -0`误判存活。前台Agent调用不可用时立即返回上报，不用即兴替代方案续跑。
- 派发留痕：派发意图（交给谁、预期产物）先落`PROGRESS.md`一行再派发，恢复断点与静默判定都以它为据；orchestrator每次返回前把下一步动作写进`TASK_STATE.md`。
- orchestrator到停点即返回：用户门禁处带回决策点清单，阻塞处带回阻塞汇报，由主会话转呈用户；用户答复落`USER_GATES.md`后主会话再次唤起orchestrator续跑。orchestrator不在回合内等待用户答复。
- 唤起orchestrator的prompt带任务描述、目标项目根、本次推进目标；orchestrator被唤起先读`TASK_STATE.md`恢复。跨段连续性只由TASK_STATE.md与任务产物承载，不依赖Agent实例存续。
- 看门狗是主会话职责——orchestrator不运行时无人核查：主会话用定时任务每15~20分钟核查PROGRESS.md与TASK_STATE的更新时间，静默超阈值即上报用户并干预（问询或重派）；每条状态行以"下次核查约HH:MM"收尾，让静默边界可预期；隔夜等跨会话场景须用持久化定时或用户侧外部监控，会话级定时随会话关闭消失。

## 前置条件

环境就绪是CLI的事，不是Agent阶段。任务开始前，orchestrator在目标项目跑`gfvbot env`；缺依赖转`gfvbot env-init`，缺源码仓转`gfvbot clone`。扫描通过或用户接受缺口后，任务进入spec阶段。

## 阶段模型

| 阶段 | owner | 门禁 | 关键产物 |
|---|---|---|---|
| spec | architect | reviewer批准SPEC评审 | architect/SPEC.md、reviewer/SPEC_REVIEW.md |
| design | architect | 设计评审批准、与SPEC无冲突 | architect/DESIGN.md、reviewer/DESIGN_REVIEW.md |
| implement | developer | 代码评审通过 | developer/IMPLEMENTATION.md、reviewer/CODE_REVIEW.md |
| verify | verifier | 对照SPEC验收标准验收通过 | verifier/VERIFY.md、reviewer/REVIEW_GATE.md |
| retro | architect | 全部产物归档 | developer/PR.md、architect/SUMMARY.md、RETROSPECTIVE.md、upstream/草稿（涉及时） |

产物路径都相对目标项目根的`tasks/<task-name>/`；`<task-name>`是任务启动时选定的稳定短标识。

## 阶段细节

### Spec

architect把任务描述转成规格合约，由插件模板`templates/spec.md`驱动。SPEC覆盖范围与目标、接口规格、行为规格、验收标准、可行性评估、验证计划。可行性评估是第一节：velox C++侧是否支持目标语义、Flink算子语义如何映射到velox语义（精确匹配、部分匹配、需要补偿）、能复用哪些既有代码、影响哪些层次，以及`feasible`、`feasible with constraints`、`feasible with upstream dependency`、`not feasible`四选一的结论。可行性评估对照`docs/gfvbot/shared/stateful-operator-implementation.md`（有状态算子实现契约：后端保证、状态句柄选型、生命周期范式）逐项核对。可行性分析经flink-velox-stateful-spec-analysis技能执行：语义映射×设施供给双维定档、查矩阵得四选一结论；任务级约束只升不降、伴随约束逐条记录，素材按SPEC模板节并入。

门禁：reviewer在SPEC_REVIEW.md上签`pass`或`fail`——没有第三种；`fail`必须给出具体修改意见。`not feasible`结论终止或降级任务。`fail`打回architect修订SPEC（原地刷新后重审）。

### Design

architect在已批准的SPEC内按`templates/design.md`产出设计：任务与输入（公式定位）、现状调研（翻译链三段诚实分级＋复用处置枚举）、契约对照（状态句柄选型、生命周期范式落位、非keyed铁律）、受影响模块与文件（velox/velox4j/gluten三仓）、执行与数据流（含对齐清单）、checkpoint语义、测试策略、风险对照陷阱表、限制清单、待裁决项。设计引用具体路径、类名、命令；套在任何项目上都成立的泛泛描述不可接受。有状态算子的设计以`docs/gfvbot/shared/stateful-operator-implementation.md`为主技术参考——生命周期钩子、initializeStateBackend五步、addInput七步范式与陷阱清单逐项对照。设计素材经flink-velox-stateful-design-analysis技能产出：机制级语义深化、现状三段诚实分级、复用处置枚举、对齐清单、限制清单与待裁决项；每条结论一句依据，待裁决项经用户门禁1逐条裁决后原地回填。

门禁：reviewer签署DESIGN_REVIEW.md，裁决`pass`/`fail`二值；评审含契约对照完整性与排版纪律（按产物契约量化标准逐节抽验）。`fail`退回设计修订，修改意见逐条给出；修订原地刷新DESIGN.md并重审。通过后停在用户门禁1。

### Implement

developer按设计实现、自编译、过格式、写单测。每个新增或修改的产品文件必须有覆盖正常路径与边界条件的单测；测试必须可独立运行。developer把按模块分组的实际改动、对设计的偏差及原因、关键行为变化、新增测试清单、测试运行结果与契约自查清单记进IMPLEMENTATION.md（按`templates/implementation.md`填写）。

门禁：reviewer签署CODE_REVIEW.md。评审必含对SPEC与设计影响清单的改动范围合规检查、单测覆盖检查与文档同步检查（IMPLEMENTATION.md所述改动、偏差与测试结果对照代码逐项一致，快照停留在返工前即必改级）；缺测试是必改级问题。`fail`退回developer，修改意见标注归属；任何修复必须重过代码评审才能进验证。

### Verify

verifier跑分层验证：单测、对验收标准的端到端运行、共享组件回归检查。端到端按flink-velox-e2e-verify技能执行：用例与证据落项目根`e2e/`证据树、全量结果汇总落`e2e/verify/RESULTS.md`，VERIFY.md引用其路径与结论。VERIFY.md记录每条命令及结果、覆盖声明、性能与回归状态——以及每个失败的症状、完整错误日志、复现步骤、环境、初判分析，让developer不用再问上下文就能开修。VERIFY.md按`templates/verify.md`填写；覆盖声明四选一（build success/targeted tests/partial verification/full verification）如实勾选。

验证裁决只有`pass`或`fail`。verifier绝不把失败归因于既有问题或环境限制就放行；归因由orchestrator与用户裁决。新算子必须至少有一条覆盖核心功能的端到端通过用例。Flink作业只有到FINISHED才算成功。

门禁：reviewer签署REVIEW_GATE.md，对照VERIFY.md逐条核对SPEC验收标准。`fail`退回developer；修复须重过代码评审与验证。验收通过后停在用户门禁3。

### Retro

developer备好PR.md（文档更新、提交计划、PR描述、合入前检查单）。改动涉及velox/velox4j/gluten仓库时，developer同时按`docs/gfvbot/shared/templates/upstream-contribution/`的路由规则备社区草稿：每个被改仓库一份PR草稿、每个算子至多一个issue草稿（改gluten仓用gluten模板，否则用velox/velox4j模板），落`tasks/<task-name>/upstream/`，经用户最终确认后才实际提交——Agent绝不自动提issue或PR。architect产出SUMMARY.md：最终范围、获批的设计偏差、各阶段评审裁决、验证覆盖、遗留风险、后续建议、经验教训是否值得沉淀进插件skills/docs（值得的给出沉淀建议）。每个参与Agent写RETROSPECTIVE.md，列失误、教训、流程建议。最终设计文档归档进目标项目自己的文档树；细则从目标项目惯例。

## 允许的回退与禁止的跳步

阶段序列严格串行。允许的回退环只有：

- spec → reviewer否决 → spec（原地刷新修订，重审）
- design → reviewer否决 → design（原地刷新修订，重审）
- implement → 代码评审失败 → implement（修复、自编译、重评审）
- implement → 验证失败 → implement（修复、单点自证、代码评审、重验证）
- implement → 验收失败 → implement（修复、代码评审、验证、重新验收）
- 任意阶段 → docs-search查询 → 原阶段

禁止的跳步，无例外：

- 从spec（或可行性）直接进实现
- 设计评审未批准直接进实现
- 代码评审未通过从实现直接进验证
- 从实现或验证直接进retro
- 用户门禁3未确认从验收直接进retro
- 跳过任何用户门禁

## 产物契约

`tasks/<task-name>/`下的产物是跨Agent的唯一事实来源；口头结论不落产物即不存在。后序阶段读产物，不读聊天记录。

```text
tasks/<task-name>/
  TASK_STATE.md                  跨Agent状态锚点
  USER_GATES.md                  用户门禁决策点与用户答复的逐轮追加记录
  PROGRESS.md                    阶段内进度心跳：owner逐里程碑追加一行（时间+agent+一句话）
  architect/    SPEC.md, DESIGN.md, SUMMARY.md, RETROSPECTIVE.md
  developer/    IMPLEMENTATION.md, PR.md, RETROSPECTIVE.md
  reviewer/     SPEC_REVIEW.md, DESIGN_REVIEW.md, CODE_REVIEW.md, REVIEW_GATE.md
  verifier/     VERIFY.md, RETROSPECTIVE.md
  upstream/     社区issue/PR草稿（按shared upstream-contribution模板，经用户确认后提交）

tmp/<task-name>/dispatch/        派发简报：每份派发落一份（owner、目标产物、必读锚点、纪律）
tmp/<task-name>/logs/            只放日志：cmd-outputs/  jobs/——不作门禁依据，随时可清理
```

产物由插件模板初始化：SPEC/DESIGN/IMPLEMENTATION/VERIFY/TASK_STATE/评审报告分别用`templates/`下的spec.md、design.md、implementation.md、verify.md、task-state.md、review-report.md，PR用pr.md，USER_GATES/PROGRESS用user-gates.md、progress.md；评审报告模板四道门禁复用，各删无关章节。有模板的产物H1/H2标题集合与编号风格照模板逐字一致——不增、不删、不改名；owner落盘前结构自检，reviewer每道评审先做结构对照，不符即`fail`按"文档"归属返工。

排版纪律（任务树全部产物适用，评审必检）：一个bullet只说一个事实，禁止用"；"串联第二个事实；表格单元格只放事实与锚点、不超过两行，推理过程移独立行；段落单行流动文本不硬换行。返工路由横向覆盖：某产物因问题X被退回时，orchestrator必须扫描同门禁全部呈报产物与任务树既有产物是否存在同类X，一并路由整改——只改被点名的一份不算完成。

e2e验证证据树在项目根`e2e/{sql,data,out,verify}/`，不在任务目录下——SQL表达验证范围、输出与对比是运行证据，跨任务沉淀为回归用例库；全量结果汇总在`e2e/verify/RESULTS.md`（每轮原地刷新），VERIFY.md只引用其路径与结论。

快照管理：产物是快照，返工**原地刷新**既有文件（DESIGN.md、CODE_REVIEW.md等），不加版本序号、不留旧版文件；orchestrator路由返工时显式点名目标产物与章节。描述对象变了（代码回退重落、口径变更）先刷新受影响产物再进下一门禁。轮次历史由TASK_STATE门禁记录每轮追加一行承载。

TASK_STATE.md是上下文恢复锚点。orchestrator在每次阶段流转时维护它：任务描述、当前阶段、各阶段状态、决策、用户约束、已知风险。每个Agent在启动与上下文压缩后都读它。

进度跟进：owner agent每到一个里程碑（读完关键参考、草拟完一节、跑完一轮构建）向`PROGRESS.md`追加一行：时间、agent、一句话——时间戳必须取`date +%F %T`实测输出，禁止估算，会话上下文携带的"当前时间"是陈旧快照，同样不可作判定依据。orchestrator派发时说明交给谁、预期产出什么，owner返回后立即汇报并更新TASK_STATE.md；owner返回而产物未落即派发失败，立即核查重派——回合内的进展核查是orchestrator职责，跨时段的静默看护是主会话职责（见运行拓扑）。用户随时`tail -f tasks/<task-name>/PROGRESS.md`感知进展。

命令输出归档：长时命令（编译、测试运行）输出重定向或tee到`tmp/<task-name>/logs/cmd-outputs/`，起描述性文件名；作业提交与崩溃现场进`tmp/<task-name>/logs/jobs/`。重跑命令前先读归档；只有输入变了才重跑。报告引用这些路径作为依据，但logs本身是临时产物——随时可清理，不裁决门禁。

## 用户门禁

三次暂停强制、不可关闭：

| 门禁 | 位置 | 触发 |
|---|---|---|
| 1 | 设计评审批准后 | 实现开始前 |
| 2 | 代码评审通过后 | 验证开始前 |
| 3 | 验收通过后 | retro开始前 |

每个暂停处的呈报与确认按以下机制执行：

- **呈报四段**：①材料清单与阅读顺序（受审产物**全文**逐一列出——inline给出或给路径与阅读指引，"已提供全文"是放行前置自检项）；②决策点清单（见下）；③答复指引——用户只需逐条答"确认/异议＋意见"，格式整理由主会话承担；④禁止引用未呈报的清单编号。
- **决策点清单**：条目从受审产物及其模板章节抽取（如设计评审后：语义映射方式、复用决策、可行性约束、测试策略、风险接受），**范围外排除项与正向决策同等呈报义务**——每条排除带理由与依据来源。每条带四要素——决策内容（可判定的取值，"合理/适中"不算）、依据来源（产物哪一节）、归属（异议时退回哪个阶段）、确认/异议选项；只取产物已有内容，不向用户索要产物未定义的字段。
- **逐条交互**：决策点一次呈一条，用户答复后才呈下一条——禁止一次性全量倾倒，也禁止把多条合并成组降低确认摩擦；产物全文阅读与逐条确认解耦，用户说"看DESIGN"即单独呈全文。
- **落盘与放行**：用户答复逐条原文追加落`USER_GATES.md`；TASK_STATE门禁行记录呈报形态（全文/仅清单）备审计；全部确认才放行，有异议的条目按归属路由给owner Agent返工，受影响产物原地刷新、对应评审从该阶段重跑。orchestrator不自己回答技术问题。

## 横切纪律

上下文窗口控制：大源文件分段读；先搜索定位再读精确区间。评审Agent按需读，不整文件读。orchestrator把必读清单压短。

辩证评审处理：architect与developer对reviewer反馈先对照实际代码与设计核实再行动。正确的接受并修复；不正确的用具体证据回应——文件路径、行号、设计章节。无证据的驳回，以及“以后再说”“超范围了”这类推诿，一律禁止；真正的范围争议交orchestrator。

Agent派发：每次派发都是全新实例；orchestrator在派发prompt里点名该owner本次要读与要写的产物，上下文恢复靠TASK_STATE.md与已有产物，不靠实例存续。
