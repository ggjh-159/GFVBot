# VERIFY——<task-name>

> Layered verification record: ratio re-measurement, correctness regression, unit tests. Verdicts are pass/fail only; ratios short of the SPEC target or any regression is a fail.

## 1. Verification info

| Item | Content |
|---|---|
| Object under verification | `<query/operator/expression name>` (one-sentence optimization summary) |
| GlutenFlink build | <commit/date, jars deployed confirmed> |
| Native Flink build | <version, the r0/r1 configurations> |
| Cluster shape | <parallelism levels, TM x slots> |
| Fixed benchmark | <100M events, 50M tps, blackhole; confs swapped in and restored by the skill> |
| Performance report | `e2e/perf/REPORT.md` (re-measurement round, refreshed in place) |
| e2e execution | flink-velox-e2e-verify skill, evidence tree `e2e/{sql,data,out,verify}/` |

## 2. Unit tests

| Suite | Command | Result | Log |
|---|---|---|---|
| `<Test>` (against the design's §5.2) | flink-velox-unit-test skill | <N passed / M failed> | `tmp/<task-name>/logs/cmd-outputs/` |

Coverage claim (one of four, ticked honestly):

- [ ] build success (compiled only, no tests run)
- [ ] targeted tests (the named cases pass)
- [ ] partial verification (some paths verified, list the uncovered ones)
- [ ] full verification (the design matrix fully covered)

## 3. Performance comparison (ratio re-measurement, same matrix via the flink-velox-performance-verify skill)

| Query | p | Before GFV/native(r0) | After GFV/native(r0) | Before GFV/native(r1) | After GFV/native(r1) | Target met? |
|---|---|---|---|---|---|---|
| | | | | | | |

Pass criterion: the after-optimization ratios reach the SPEC target; the re-measurement matrix matches the baseline (same queries, same p levels, same fixed benchmark); all jobs FINISHED; the GFV round reuse=false only; missing levels or queries are listed in the coverage claim.

## 4. Correctness regression

| Case | SQL/query | Job status | Result | Evidence |
|---|---|---|---|---|
| | <SPEC query set: nexmark qNN or self-constructed> | <FINISHED only counts as success> | <consistent/inconsistent> | `e2e/out/` |

Pass criterion: compared as the folded final result set (`+I`/`+U` add, `-U`/`-D` subtract) — no extra rows, no missing rows, no field-value differences; any regressing query fails the verification.

Checked against each SPEC acceptance criterion:

| Acceptance criterion | Matching case | Met? |
|---|---|---|

## 5. Failure details (if any)

Record every failure item by item so the developer can start fixing without asking for context:

- Symptom: <one sentence>
- Full error log: `tmp/<task-name>/logs/<file>`
- Reproduction steps: <command sequence>
- Environment: <cluster / build / data>
- First-pass analysis: <first-layer attribution, not a final conclusion>

## 6. Conclusion

**Verification verdict: pass / fail**

- pass requires: §2 unit tests all pass, §3 ratios meet the target with a matching matrix, §4 no regression
- on fail: list the blockers, pointing to the §5 details
