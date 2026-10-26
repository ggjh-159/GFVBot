# TEST_REPORT — <task-name>

> e2e dual-run comparison report. Passes only when every case is exactly consistent and there is no regression.

## 1. Test Info

| Item | Content |
|---|---|
| Target function | `<FUNCTION(args)>` |
| Native Flink version | <1.19.2, cluster form> |
| GlutenFlink build | <commit/date, jars deployed> |
| Comparison method | flink-velox-e2e-verify skill (exact compare after changelog multiset reconstruction) |
| Cases and data | project-root `e2e/{sql,data,out,verify}/` (persistent evidence tree) |
| Results rollup | `e2e/verify/RESULTS.md` (refreshed in place each round) |

## 2. Case List and Results

| Case | Intent (design §8) | Changelog shape | Native final | GFV final | Verdict |
|---|---|---|---|---|---|
| 001_basic | basic projection | append-only | N rows | N rows | consistent/inconsistent |
| 002_null | NULL propagation | | | | |
| 003_boundary | boundary values | | | | |
| 004_nested | combined with other expressions | | | | |
| 005_agg | aggregation context | retract stream | | | |

Verdict rule: no more rows, no fewer rows, and no field value differences — otherwise inconsistent; a job that never reached FINISHED fails the case.

## 3. Coverage Check

| Design §8 matrix entry | Case | Covered? |
|---|---|---|
| | | |

## 4. Inconsistency Details (if any)

<per case: raw changelog excerpt, reconstructed final results of both ends, differing rows (missing / extra / field mismatch)>

## 5. Regression

| Regression scope | Result |
|---|---|
| Representative cases of already-mapped expressions | <all consistent / anomaly, details> |

## 6. Conclusion

**Test conclusion: pass / fail**

- Pass conditions: §2 all cases consistent, §3 coverage has no gap, §5 no regression
- On fail: list the blocking items, pointing to the §4 details
