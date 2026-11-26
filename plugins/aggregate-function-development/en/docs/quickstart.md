# Aggregate function development quickstart

## Prerequisites

```bash
gfvbot install aggregate-function-development   # install the plugin (skills/docs/templates)
gfvbot clone                                    # clone the four repos into repos/
gfvbot env && gfvbot env-init                   # environment scan and completion
```

After installing (or reinstalling), start a **fresh session** in the project directory before running a task: agents load only at session start, so an already-open session cannot see the newly landed `.claude/agents/`; `/agents` listing the 5 `aggregate-function-*` agents means ready.

The first GFV build and cluster start are handled by the workflow: the implement stage runs the flink-velox-build skill to compile, deploy jars, and restart the cluster — no manual build before the task.

Aggregate facilities and test fixture first: the spec and design stages check the aggregate-related sections of `docs/gfvbot/shared/stateful-operator-implementation.md` throughout — the `makeAggregateInfos` aggregate facilities and the test SetUp registration order (prestosql baseline first, flinksql overwrite second). Registration goes only through the flinksql namespace, and existing aggregate implementations are only extended, never modified.

## Example task: a custom aggregate function (e.g. COUNT DISTINCT)

A typical task — add an aggregate function to the flinksql namespace: the velox C++ `Aggregate` kernel (the accumulate/merge/finalize/partial chain, type matrix, NULL and empty-set semantics), the registration entry, unit tests, and nexmark regression:

1. **SPEC**: fill the `spec.md` template; the feasibility assessment is the first section — verify existing implementations, the type matrix, the registration path, and the batch integration point item by item (write "to be verified" when it cannot be found)
2. **Design**: fill `design.md` — current-state survey (three-stage grading + reuse dispositions), plan (type matrix, intermediate-state layout, the chain, NULL semantics, registration entry), impacted files, unit-test matrix and nexmark regression set, risks and pending decisions
3. **SPEC/design review**: the reviewer issues pass/fail per `review-report.md`; after design approval, user gate 1 releases
4. **Implement**: code per the design (aggregate kernel + registration + unit-test fixture); fill `implementation.md` (including the scenario self-check); after code review pass, user gate 2 releases
5. **Verify**: unit tests (flink-velox-unit-test) plus e2e dual runs (flink-velox-e2e-verify, folded result sets against native Flink) plus nexmark q17 → q15/q16/q4; fill `verify.md`; final acceptance plus user gate 3
6. **Retro**: PR.md, SUMMARY.md; when upstream repos are touched, prepare drafts per the upstream-contribution templates and submit only after confirmation

## Workflow overview

| Stage | Owner | Gate | Key artifacts |
|---|---|---|---|
| spec | architect | SPEC review pass | architect/SPEC.md |
| design | architect | design review pass + user gate 1 | architect/DESIGN.md |
| implement | developer | code review pass + user gate 2 | developer/IMPLEMENTATION.md |
| verify | verifier | final acceptance pass + user gate 3 | verifier/VERIFY.md |
| retro | architect | all artifacts archived | developer/PR.md, architect/SUMMARY.md |

Live task state is kept in `tasks/<task-name>/TASK_STATE.md` (shared template `docs/gfvbot/shared/templates/task-state.md`) and recovered from there after a session break; intra-stage progress shows in the `PROGRESS.md` heartbeat.

## Prompt template

`gfvbot prompt aggregate-function-development` prints the task template; `--task` has the AI fill it in.
