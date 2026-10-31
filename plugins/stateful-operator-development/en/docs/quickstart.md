# Stateful operator development quickstart

## Prerequisites

```bash
gfvbot install stateful-operator-development   # install the plugin (skills/docs/templates)
gfvbot clone                                   # clone the four repos into repos/
gfvbot env && gfvbot env-init                  # environment scan and completion
```

The first GFV build and cluster start are handled by the workflow: the implement stage runs the flink-velox-build skill to compile, deploy jars, and restart the cluster — no manual build before the task.

Contract first: the spec and design stages check `docs/gfvbot/shared/stateful-operator-implementation.md` throughout — backend guarantees, state handle selection, lifecycle patterns (five backend-construction steps, seven-step addInput), and the pitfall list.

## Example task: streaming deduplication operator

A typical task — deduplicate by key, emit only the first row (+I), drop later duplicates, and store the seen marker in ValueState:

1. **SPEC**: fill the `spec.md` template; the feasibility assessment is the first section, checked item by item against the implementation-contract doc (ValueState handle; no partition semantics, use VoidNamespace)
2. **Design**: fill `design.md` — current-state survey (three-stage grading of the translation chain + reuse dispositions), contract matching (handle selection, five/seven-step placement with the alignment list, non-keyed iron rule), impacted files across the three repos, unit-test matrix (appendOnly/kinds/changelog/snapshot round-trip/rescale), risks against the pitfall table, limitations and pending decisions
3. **SPEC/design review**: the reviewer issues pass/fail per `review-report.md`; after design approval, user gate 1 releases
4. **Implement**: code per the design (velox node + operator + planner branch + unit tests, velox4j mirror, gluten shadow override); fill `implementation.md` (including the contract self-check); after code review pass, user gate 2 releases
5. **Verify**: unit tests (flink-velox-unit-test) plus e2e (flink-velox-e2e-verify, diffing changelogs against native Flink); fill `verify.md`; final acceptance plus user gate 3
6. **Retro**: PR.md, SUMMARY.md; when upstream repos are touched, prepare drafts per the upstream-contribution templates and submit only after confirmation

## Workflow overview

| Stage | Owner | Gate | Key artifacts |
|---|---|---|---|
| spec | architect | SPEC review pass | architect/SPEC.md |
| design | architect | design review pass + user gate 1 | architect/DESIGN.md |
| implement | developer | code review pass + user gate 2 | developer/IMPLEMENTATION.md |
| verify | verifier | final acceptance pass + user gate 3 | verifier/VERIFY.md |
| retro | architect | all artifacts archived | developer/PR.md, architect/SUMMARY.md |

Live task state is kept in `tasks/<task-name>/TASK_STATE.md` (template `task-state.md`) and recovered from there after a session break; intra-stage progress shows in the `PROGRESS.md` heartbeat.

## Prompt template

`gfvbot prompt stateful-operator-development` prints the task template; `--task` has the AI fill it in.
