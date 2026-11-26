# VERIFY——<task-name>

> Layered verification record: unit tests, end-to-end dual runs, nexmark aggregate regression. Verdicts are pass/fail only; any failing case is a fail.

## 1. Verification info

| Item | Content |
|---|---|
| Object under verification | `<SQL function name>` (one-sentence change summary) |
| GlutenFlink build | <commit/date, jars deployed confirmed> |
| Cluster shape | <parallelism, TM configuration> |
| e2e execution | flink-velox-e2e-verify skill |
| Cases and data | project-root `e2e/{sql,data,out,verify}/` evidence tree |
| Result rollup | `e2e/verify/RESULTS.md` (refreshed in place each round) |

## 2. Unit tests

| Suite | Command | Result | Log |
|---|---|---|---|
| `<Test>` (against the design's §5.1 matrix) | flink-velox-unit-test skill | <N passed / M failed> | `tmp/<task-name>/logs/cmd-outputs/` |

Coverage claim (one of four, ticked honestly):

- [ ] build success (compiled only, no tests run)
- [ ] targeted tests (the named cases pass)
- [ ] partial verification (some paths verified, list the uncovered ones)
- [ ] full verification (the design matrix fully covered)

## 3. End-to-end dual runs

| Case | SQL/query | Parallelism | Job status | Result | Evidence |
|---|---|---|---|---|---|
| | <nexmark q17/q15/q16/q4 or self-constructed> | | <FINISHED only counts as success> | <consistent/inconsistent> | `e2e/out/` |

Pass criterion: aggregate output compared as the folded final result set (`+I`/`+U` add, `-U`/`-D` subtract) — no extra rows, no missing rows, no field-value differences; a difference in retraction-pair counts is not a failure, only a differing final result set is; a job that did not reach FINISHED fails the case.

Checked against each SPEC acceptance criterion:

| Acceptance criterion | Matching case | Met? |
|---|---|---|

## 4. Regression

| Regression scope | Result |
|---|---|
| Existing cases of existing aggregates and the shared aggregate facilities (`makeAggregateInfos` / RowContainer path) | <all consistent / anomaly details> |
| nexmark aggregate queries (q17 → q15/q16/q4) | |

## 5. Failure details (if any)

Record every failure item by item so the developer can start fixing without asking for context:

- Symptom: <one sentence>
- Full error log: `tmp/<task-name>/logs/<file>`
- Reproduction steps: <command sequence>
- Environment: <cluster / build / data>
- First-pass analysis: <first-layer attribution, not a final conclusion>

## 6. Conclusion

**Verification verdict: pass / fail**

- pass requires: §2 unit tests all pass, §3 cases all FINISHED and consistent, §4 no regression
- on fail: list the blockers, pointing to the §5 details
