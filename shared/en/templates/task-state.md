# TASK_STATE — <task-name>

> The single authoritative record of task state. The orchestrator updates it at every stage transition; recover from here after a session break or context compaction.

## Current state

| Item | Content |
|---|---|
| Current stage | <spec/design/implement/verify/retro> |
| Next action | <one sentence: who does what> |
| Blockers | <none / description + waiting on whom> |

## Gate records

Artifacts refresh in place; round history lives only here — one appended line per gate round. Review gates get one row each, following this plugin's workflow stage model; names, verdict words, and report paths are defined by the workflow:

| Gate | Round | Verdict | Report | Date |
|---|---|---|---|---|
| <review gate, per the workflow stage model> | 1 | <verdict word per the workflow> | `tasks/<task-name>/reviewer/<report>.md` | |
| User gate 1 (after design) | — | <released/not released> | `tasks/<task-name>/USER_GATES.md` | |
| User gate 2 (<position per the workflow>) | — | <released/not released> | `tasks/<task-name>/USER_GATES.md` | |
| User gate 3 (<position per the workflow>) | — | <released/not released> | `tasks/<task-name>/USER_GATES.md` | |

## Artifact index

```text
tasks/<task-name>/
  TASK_STATE.md                  this file: cross-agent state anchor
  USER_GATES.md                  per-round appended record of user-gate decision points and user replies
  PROGRESS.md                    intra-stage progress heartbeat: one appended line per milestone by the owner (time + agent + one sentence)
  <agent>/                       per-agent artifacts: directories and file names follow this plugin's workflow artifact contract
  upstream/                      community issue/PR drafts (per the shared upstream-contribution templates, filed after user confirmation)

tmp/<task-name>/logs/            logs only (cleanable anytime, never gate evidence): cmd-outputs/  jobs/
```

Verification evidence trees live at the project root — outside task directories, accreting across tasks into a regression bank: `e2e/{sql,data,out,verify}/` (full-result rollup in `e2e/verify/RESULTS.md`) and the performance-comparison tree `e2e/perf/`.

## Snapshot and verdict conventions

- Artifacts are snapshots: rework refreshes the existing file in place (`DESIGN.md`, `CODE_REVIEW.md`), no version suffixes, no old copies; round history is carried by the appended gate records above
- When the described object has changed (code rolled back and relanded, scope redefined), refresh the affected artifacts before entering the next gate
- Verbal conclusions do not count: a verdict exists only when written into the file the table above points to; user-gate replies are appended verbatim to `USER_GATES.md`

## Recovery context

<three to five lines: task goal, how far it got, what it is currently stuck on, environment facts such as cluster/build state>
