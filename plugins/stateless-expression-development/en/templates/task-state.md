# TASK_STATE — <task-name>

> The single authoritative record of task state. Updated at the end of every stage and after every gate ruling; recover context from here after a session break.

## Current State

| Item | Content |
|---|---|
| Current stage | <spec/design/implement/verify/retro> |
| Next action | <one sentence: who does what> |
| Blockers | <none / description + waiting on whom> |

## Gate Records

Artifacts refresh in place; round history lives only here — one appended line per audit round:

| Gate | Round | Ruling | Report | Date |
|---|---|---|---|---|
| Design audit | 1 | <pass/fail/not started> | `tmp/<task-name>/reviewer/DESIGN_AUDIT.md` | |
| Code audit | 1 | <pass/fail/not started> | `tmp/<task-name>/reviewer/CODE_AUDIT.md` | |
| Result audit | 1 | <pass/fail/not started> | `tmp/<task-name>/reviewer/RESULT_AUDIT.md` | |
| User gate 1 (after design) | — | <released/pending> | `tmp/<task-name>/USER_GATES.md` | |
| User gate 2 (before code delivery) | — | <released/pending> | `tmp/<task-name>/USER_GATES.md` | |
| User gate 3 (after acceptance) | — | <released/pending> | `tmp/<task-name>/USER_GATES.md` | |

## Artifact Index

```
tmp/<task-name>/
  TASK_STATE.md                 this file: cross-agent shared state anchor
  USER_GATES.md                 per-round appended record of user-gate decision points and user replies
  architect/    SPEC.md  DESIGN.md  SUMMARY.md
  developer/    IMPLEMENTATION.md  PR.md
  reviewer/     DESIGN_AUDIT.md  CODE_AUDIT.md  RESULT_AUDIT.md
  verifier/     TEST_REPORT.md
  upstream/                     community issue/PR drafts (filed only after user confirmation)
  logs/                         transient (cleanable anytime, never gate evidence): cmd-outputs/  jobs/
```

The project root additionally holds the `e2e/{sql,data,out,verify}/` verification evidence tree — outside tmp, preserved after the task ends; the full-result rollup lives in `e2e/verify/RESULTS.md`.

## Snapshot and Ruling Conventions

- Artifacts are snapshots: rework refreshes existing files in place (`DESIGN.md`, `DESIGN_AUDIT.md`) — no version suffixes, no old copies left behind; round history is carried by the appended per-round rows in the gate records
- When the described object has changed (code rolled back and relanded, scope redefined), refresh the affected artifacts before entering the next gate
- Verbal rulings do not count: a ruling exists only when written to the file named in the table above; user-gate replies are recorded verbatim in `USER_GATES.md`

## Context Recovery Notes

<three to five lines: task goal, progress so far, the current blocking problem, environment facts such as cluster/build state>
