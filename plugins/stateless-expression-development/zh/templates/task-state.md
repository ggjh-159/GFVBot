# TASK_STATE——<task-name>

> 任务状态的唯一权威记录。每个阶段结束、每次门禁裁决后更新；会话中断后从这里恢复上下文。

## 当前状态

| 项 | 内容 |
|---|---|
| 当前阶段 | <spec/design/implement/verify/retro> |
| 下一步动作 | <一句话：谁、做什么> |
| 阻塞项 | <无/描述+等待谁> |

## 门禁记录

产物原地刷新，轮次历史只在这里——每轮审计追加一行：

| 门禁 | 轮次 | 裁决 | 报告 | 日期 |
|---|---|---|---|---|
| 设计审计 | 1 | <通过/不通过/未开始> | `tasks/<task-name>/reviewer/DESIGN_AUDIT.md` | |
| 代码审计 | 1 | <通过/不通过/未开始> | `tasks/<task-name>/reviewer/CODE_AUDIT.md` | |
| 结果审计 | 1 | <通过/不通过/未开始> | `tasks/<task-name>/reviewer/RESULT_AUDIT.md` | |
| 用户门禁1（设计后） | — | <已放行/未放行> | `tasks/<task-name>/USER_GATES.md` | |
| 用户门禁2（代码交付前） | — | <已放行/未放行> | `tasks/<task-name>/USER_GATES.md` | |
| 用户门禁3（验收后） | — | <已放行/未放行> | `tasks/<task-name>/USER_GATES.md` | |

## 产物索引

```
tasks/<task-name>/
  TASK_STATE.md                 本文件：跨Agent共享状态锚点
  USER_GATES.md                 用户门禁决策点与用户答复的逐轮追加记录
  PROGRESS.md                   阶段内进度心跳：owner逐里程碑追加一行（时间+agent+一句话）
  architect/    SPEC.md  DESIGN.md  SUMMARY.md
  developer/    IMPLEMENTATION.md  PR.md
  reviewer/     DESIGN_AUDIT.md  CODE_AUDIT.md  RESULT_AUDIT.md
  verifier/     TEST_REPORT.md
  upstream/                     社区issue/PR草稿（经用户确认后提交）

tmp/<task-name>/logs/           只放日志（随时可清理，不作裁决依据）：cmd-outputs/  jobs/
```

项目根另有`e2e/{sql,data,out,verify}/`验证证据树——不在任务目录下、任务结束保留，全量结果汇总在`e2e/verify/RESULTS.md`。

## 快照与裁决惯例

- 产物是快照：返工原地刷新既有文件（`DESIGN.md`、`DESIGN_AUDIT.md`），不加版本序号、不留旧版文件；轮次历史由门禁记录每轮追加承载
- 描述对象变了（代码回退重落、口径变更）先刷新受影响产物，再进下一门禁
- 口头结论不算数：任何裁决必须落到上表指向的文件里才有效；用户门禁的答复原文落`USER_GATES.md`

## 恢复上下文要点

<三五行：任务目标、已完成到哪、当前正卡在什么问题上、重启集群/构建状态等环境事实>
