# VERIFY——<task-name>

> 分层验证记录：比值复测、正确性回归、单测。裁决只有pass/fail；比值未达SPEC目标或任一回归即fail。

## 1. 验证信息

| 项 | 内容 |
|---|---|
| 验证对象 | `<查询/算子/表达式名>`（优化改动概要一句） |
| GlutenFlink构建 | <commit/日期，jars部署确认> |
| 原生Flink构建 | <版本，r0/r1两轮配置> |
| 集群形态 | <并行度档位、TM×slots> |
| 固定基准 | <1亿events、5000w tps、blackhole；conf由技能换入并恢复> |
| 性能报告 | `e2e/perf/REPORT.md`（复测轮，原地刷新） |
| e2e执行方式 | flink-velox-e2e-verify技能，证据树`e2e/{sql,data,out,verify}/` |

## 2. 单元测试

| 套件 | 命令 | 结果 | 日志 |
|---|---|---|---|
| `<Test>`（对照设计§5.2） | flink-velox-unit-test技能 | <N通过/M失败> | `tmp/<task-name>/logs/cmd-outputs/` |

覆盖声明（四选一，如实勾选）：

- [ ] build success（仅编译通过，无测试运行）
- [ ] targeted tests（指定用例通过）
- [ ] partial verification（部分路径验证，列未覆盖项）
- [ ] full verification（设计矩阵全覆盖）

## 3. 性能对比（比值复测，按flink-velox-performance-verify技能同矩阵重跑）

| 查询 | p | 优化前GFV/native(r0) | 优化后GFV/native(r0) | 优化前GFV/native(r1) | 优化后GFV/native(r1) | 达标？ |
|---|---|---|---|---|---|---|
| | | | | | | |

判定标准：优化后比值达到SPEC目标；复测矩阵与基线一致（同查询、同p档、同固定基准）；所有作业FINISHED；GFV轮仅reuse=false；缺档或缺查询在覆盖声明列出。

## 4. 正确性回归

| 用例 | SQL/查询 | 作业状态 | 结果判定 | 证据 |
|---|---|---|---|---|
| | <SPEC查询集：nexmark qNN或自构造> | <FINISHED才算成功> | <一致/不一致> | `e2e/out/` |

判定标准：按最终结果集折叠比对（`+I`/`+U`加、`-U`/`-D`减），不多、不少、任一字段值一致；任一查询回归即fail。

对照SPEC验收标准逐条：

| 验收标准 | 对应用例 | 满足？ |
|---|---|---|

## 5. 失败明细（若有）

每个失败逐条记录，让developer不问上下文即可开修：

- 症状：<一句话>
- 完整错误日志：`tmp/<task-name>/logs/<文件>`
- 复现步骤：<命令序列>
- 环境：<集群/构建/数据>
- 初判分析：<第一层归因，不下最终结论>

## 6. 结论

**验证结论：pass / fail**

- pass条件：§2单测全过、§3比值达标且矩阵一致、§4无回归
- fail时：列出阻断项，指向§5明细
