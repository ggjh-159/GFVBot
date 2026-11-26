# VERIFY——<task-name>

> 分层验证记录：单测、端到端双跑、nexmark聚合回归。裁决只有pass/fail；任何失败用例即fail。

## 1. 验证信息

| 项 | 内容 |
|---|---|
| 验证对象 | `<SQL函数名>`（改动概要一句） |
| GlutenFlink构建 | <commit/日期，jars部署确认> |
| 集群形态 | <并行度、TM配置> |
| e2e执行方式 | flink-velox-e2e-verify技能 |
| 用例与数据 | 项目根`e2e/{sql,data,out,verify}/`证据树 |
| 结果汇总 | `e2e/verify/RESULTS.md`（每轮原地刷新） |

## 2. 单元测试

| 套件 | 命令 | 结果 | 日志 |
|---|---|---|---|
| `<Test>`（对照设计§5.1矩阵） | flink-velox-unit-test技能 | <N通过/M失败> | `tmp/<task-name>/logs/cmd-outputs/` |

覆盖声明（四选一，如实勾选）：

- [ ] build success（仅编译通过，无测试运行）
- [ ] targeted tests（指定用例通过）
- [ ] partial verification（部分路径验证，列未覆盖项）
- [ ] full verification（设计矩阵全覆盖）

## 3. 端到端双跑

| 用例 | SQL/查询 | 并行度 | 作业状态 | 结果判定 | 证据 |
|---|---|---|---|---|---|
| | <nexmark q17/q15/q16/q4或自构造> | | <FINISHED才算成功> | <一致/不一致> | `e2e/out/` |

判定标准：聚合输出按最终结果集折叠比对（`+I`/`+U`加、`-U`/`-D`减），不多、不少、任一字段值一致；回撤对数量差异不是失败，最终结果集不一致才是；作业未达FINISHED即该用例失败。

对照SPEC验收标准逐条：

| 验收标准 | 对应用例 | 满足？ |
|---|---|---|

## 4. 回归

| 回归范围 | 结果 |
|---|---|
| 既有聚合与共用聚合设施（`makeAggregateInfos`/RowContainer路径）既有用例 | <全部一致/异常详情> |
| nexmark聚合查询（q17→q15/q16/q4） | |

## 5. 失败明细（若有）

每个失败逐条记录，让developer不问上下文即可开修：

- 症状：<一句话>
- 完整错误日志：`tmp/<task-name>/logs/<文件>`
- 复现步骤：<命令序列>
- 环境：<集群/构建/数据>
- 初判分析：<第一层归因，不下最终结论>

## 6. 结论

**验证结论：pass / fail**

- pass条件：§2单测全过、§3用例全FINISHED且一致、§4无回归
- fail时：列出阻断项，指向§5明细
