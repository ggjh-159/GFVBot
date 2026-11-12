# USER_GATES — <task-name>

> Per-round appended record of user-gate decision points and user replies. The orchestrator presents the decision-point checklist; user replies land in this file verbatim; release only when every entry is confirmed.

## Gate <N> (<position>, <trigger>)

Presented at: <YYYY-MM-DD HH:MM> | Artifact under review: `<artifact path>`

Key-decision checklist (four elements each — decision / evidence source / attribution / choice):

| # | Decision (a decidable value) | Evidence source (artifact section) | Attribution (which stage an objection returns to) | Confirm/object |
|---|---|---|---|---|
| 1 | | | | <awaiting reply: confirm/object + opinion> |

User replies (appended verbatim):

- <time + verbatim reply>
