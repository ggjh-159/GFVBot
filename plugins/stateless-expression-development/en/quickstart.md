# Stateless Expression Development Quickstart

## Prerequisites

```bash
gfvbot install stateless-expression-development   # install the plugin (skills/docs/templates)
gfvbot clone                                      # clone the four repos into repos/
gfvbot env && gfvbot env-init                     # environment scan and fix-up
bash <flink-velox-build skill>/bin/compile.sh     # build and deploy jars
/opt/flink/bin/start-cluster.sh                   # start the cluster
```

## Example Task: Migrate `UPPER` to the flinksql Namespace

A typical task — velox already has prestosql `upper`, but the iron rule requires a GFV-owned registration under the flinksql namespace:

1. **SPEC**: fill the `spec.md` template; the semantic baseline is `docs/gfvbot/shared/flink-expressions/string/UPPER.md`
2. **Design**: fill `design.md` — the doc card's "velox implementation" section shows prestosql already has `upper`; check the semantic comparison dimension by dimension (NULL behavior, character counting); the registration design goes into a new file under `velox/functions/flinksql/`; the mapping design adds the `RexCallConverterFactory` entry; produce the unit-test/e2e coverage matrices
3. **Design audit**: the reviewer issues a ruling with section A of `audit-report.md` (pass/fail); after it passes, user gate 1 releases the next stage
4. **Implement**: code per the design; compile and deploy (flink-velox-build), unit tests (flink-velox-unit-test), lightweight e2e self-check; fill `implementation.md`; after the code audit (section B) passes, user gate 2 releases delivery
5. **Verify**: build the full SQL set per the design §8 matrix (fixed filesystem input + print sink), run both native Flink and GlutenFlink, compare exactly after changelog reconstruction (flink-velox-e2e-verify); fill `test-report.md`; result audit (section C) + regression
6. **Retro**: archive artifacts and update `TASK_STATE.md`

## Workflow Overview

| Stage | Owner | Gate | Key artifact |
|---|---|---|---|
| spec | architect | — | SPEC.md |
| design | architect | design audit + user gate 1 | DESIGN.md |
| implement | developer | code audit + user gate 2 | IMPLEMENTATION.md |
| verify | verifier | result audit + user gate 3 | TEST_REPORT.md |
| retro | architect | — | SUMMARY.md |

Task state lives in `tasks/<task-name>/TASK_STATE.md`; recover from it after a session break.

## Prompt Template

`gfvbot prompt stateless-expression-development` prints the task template; `--task` has the AI fill it in.
