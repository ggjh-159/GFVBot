# TASK_STATE——<task-name>

> 任务状态的唯一权威记录。orchestrator在每次阶段流转时更新；会话中断或上下文压缩后从这里恢复。

## 当前状态

| 项 | 内容 |
|---|---|
| 当前阶段 | <spec/design/implement/verify/retro> |
| 下一步动作 | <一句话：谁、做什么> |
| 阻塞项 | <无/描述+等待谁> |

## 门禁记录

产物原地刷新，轮次历史只在这里——每轮门禁追加一行：

| 门禁 | 轮次 | 裁决 | 报告 | 日期 |
|---|---|---|---|---|
| SPEC评审 | 1 | <pass/fail/未开始> | `tasks/<task-name>/reviewer/SPEC_REVIEW.md` | |
| 设计评审 | 1 | <pass/fail/未开始> | `tasks/<task-name>/reviewer/DESIGN_REVIEW.md` | |
| 用户门禁1（设计后） | — | <已放行/未放行> | `tasks/<task-name>/USER_GATES.md` | |
| 代码评审 | 1 | <pass/fail/未开始> | `tasks/<task-name>/reviewer/CODE_REVIEW.md` | |
| 用户门禁2（验证前） | — | <已放行/未放行> | `tasks/<task-name>/USER_GATES.md` | |
| 最终验收 | 1 | <pass/fail/未开始> | `tasks/<task-name>/reviewer/REVIEW_GATE.md` | |
| 用户门禁3（retro前） | — | <已放行/未放行> | `tasks/<task-name>/USER_GATES.md` | |

## 产物索引

```
tasks/<task-name>/
  TASK_STATE.md                  本文件：跨Agent状态锚点
  USER_GATES.md                  用户门禁决策点与用户答复的逐轮追加记录
  PROGRESS.md                    阶段内进度心跳：owner逐里程碑追加一行
  architect/    SPEC.md  DESIGN.md  SUMMARY.md  RETROSPECTIVE.md
  developer/    IMPLEMENTATION.md  PR.md  RETROSPECTIVE.md
  reviewer/     SPEC_REVIEW.md  DESIGN_REVIEW.md  CODE_REVIEW.md  REVIEW_GATE.md
  verifier/     VERIFY.md  RETROSPECTIVE.md
  upstream/     社区issue/PR草稿（按shared upstream-contribution模板，经用户确认后提交）

tmp/<task-name>/logs/            只放日志（随时可清理，不作裁决依据）：cmd-outputs/  jobs/
```

e2e验证证据树在项目根`e2e/{sql,data,out,verify}/`——不在任务目录下、跨任务沉淀为回归用例库，全量结果汇总在`e2e/verify/RESULTS.md`。

## 快照与裁决惯例

- 产物是快照：返工原地刷新既有文件（`DESIGN.md`、`CODE_REVIEW.md`），不加版本序号、不留旧版文件；轮次历史由门禁记录每轮追加承载
- 描述对象变了（代码回退重落、口径变更）先刷新受影响产物，再进下一门禁
- 口头结论不算数：任何裁决必须落到上表指向的文件里才有效；用户门禁的答复原文逐条落`USER_GATES.md`

## 恢复上下文要点

<三五行：任务目标、已完成到哪、当前正卡在什么问题上、集群/构建状态等环境事实>
