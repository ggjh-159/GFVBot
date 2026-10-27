# TASK_STATE — <task-name>

> The single authoritative record of task state. The orchestrator updates it at every stage transition; recover from here after a session break or context compaction.

## Current state

| Item | Content |
|---|---|
| Current stage | <spec/design/implement/verify/retro> |
| Next action | <one sentence: who does what> |
| Blockers | <none / description + waiting on whom> |

## Gate records

Artifacts refresh in place; round history lives only here — one appended line per gate round:

| Gate | Round | Verdict | Report | Date |
|---|---|---|---|---|
| SPEC review | 1 | <pass/fail/not started> | `tasks/<task-name>/reviewer/SPEC_REVIEW.md` | |
| Design review | 1 | <pass/fail/not started> | `tasks/<task-name>/reviewer/DESIGN_REVIEW.md` | |
| User gate 1 (after design) | — | <released/not released> | `tasks/<task-name>/USER_GATES.md` | |
| Code review | 1 | <pass/fail/not started> | `tasks/<task-name>/reviewer/CODE_REVIEW.md` | |
| User gate 2 (before verification) | — | <released/not released> | `tasks/<task-name>/USER_GATES.md` | |
| Final acceptance | 1 | <pass/fail/not started> | `tasks/<task-name>/reviewer/REVIEW_GATE.md` | |
| User gate 3 (before retro) | — | <released/not released> | `tasks/<task-name>/USER_GATES.md` | |

## Artifact index

```text
tasks/<task-name>/
  TASK_STATE.md                  this file: cross-agent state anchor
  USER_GATES.md                  per-round appended record of user-gate decision points and user replies
  PROGRESS.md                    intra-stage progress heartbeat: one appended line per milestone by the owner
  architect/    SPEC.md  DESIGN.md  SUMMARY.md  RETROSPECTIVE.md
  developer/    IMPLEMENTATION.md  PR.md  RETROSPECTIVE.md
  reviewer/     SPEC_REVIEW.md  DESIGN_REVIEW.md  CODE_REVIEW.md  REVIEW_GATE.md
  verifier/     VERIFY.md  RETROSPECTIVE.md
  upstream/     community issue/PR drafts (per the shared upstream-contribution templates, filed after user confirmation)

tmp/<task-name>/logs/            logs only (cleanable anytime, never gate evidence): cmd-outputs/  jobs/
```

The e2e verification evidence tree lives at the project root, `e2e/{sql,data,out,verify}/` — outside task directories, accreting across tasks into a regression bank; the full-result rollup lives in `e2e/verify/RESULTS.md`.

## Snapshot and verdict conventions

- Artifacts are snapshots: rework refreshes the existing file in place (`DESIGN.md`, `CODE_REVIEW.md`), no version suffixes, no old copies; round history is carried by the appended gate records above
- When the described object has changed (code rolled back and relanded, scope redefined), refresh the affected artifacts before entering the next gate
- Verbal conclusions do not count: a verdict exists only when written into the file the table above points to; user-gate replies are appended verbatim to `USER_GATES.md`

## Recovery context

<three to five lines: task goal, how far it got, what it is currently stuck on, environment facts such as cluster/build state>
