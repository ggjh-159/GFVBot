# VERIFY — <task-name>

> Layered verification record: unit tests, end-to-end, regression. Verdicts are pass/fail only; any failed case means fail.

## 1. Verification info

| Item | Content |
|---|---|
| Verification target | `<operator-name>` (one-sentence change summary) |
| GlutenFlink build | <commit/date, jar deployment confirmed> |
| Cluster shape | <parallelism, TM config> |
| e2e execution | flink-velox-e2e-verify skill |
| Cases and data | project-root `e2e/{sql,data,out,verify}/` evidence tree |
| Result rollup | `e2e/verify/RESULTS.md` (refreshed in place each round) |

## 2. Unit tests

| Suite | Command | Result | Log |
|---|---|---|---|
| `<Test>` (against the design §7.1 matrix) | flink-velox-unit-test skill | <N pass/M fail> | `tmp/<task-name>/logs/cmd-outputs/` |

Coverage claim (choose one, honestly):

- [ ] build success (compile only, no tests run)
- [ ] targeted tests (named cases pass)
- [ ] partial verification (some paths verified; list the uncovered ones)
- [ ] full verification (full design-matrix coverage)

## 3. End-to-end

| Case | SQL / query | Parallelism | Job state | Verdict | Evidence |
|---|---|---|---|---|---|
| | <nexmark qNN/hand-built> | | <FINISHED is the only success> | <consistent/inconsistent> | `e2e/out/` |

Pass criteria: against the baseline (native Flink output / changelog replay), nothing extra, nothing missing, every field value equal; a job that never reaches FINISHED fails the case.

Against the SPEC acceptance criteria, item by item:

| Acceptance criterion | Covering case | Met? |
|---|---|---|

## 4. Regression

| Regression scope | Result |
|---|---|
| Shared components (planner dispatch / operator chain / state backend), existing cases | <all consistent / anomaly details> |
| Covered nexmark queries | |

## 5. Performance status

<This section exists only under constraints: throughput/state size vs the SPEC bounds; write "no performance constraints" otherwise>

## 6. Failure detail (if any)

Record each failure so the developer can start fixing without asking for context:

- Symptom: <one sentence>
- Full error log: `tmp/<task-name>/logs/<file>`
- Reproduction: <command sequence>
- Environment: <cluster/build/data>
- First-pass analysis: <first-layer attribution, not a final conclusion>

## 7. Verdict

**Verification verdict: pass / fail**

- pass requires: §2 unit tests all green, §3 cases all FINISHED and consistent, §4 no regression
- on fail: list the blockers, pointing to the §6 detail
