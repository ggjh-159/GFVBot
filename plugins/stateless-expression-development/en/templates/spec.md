# SPEC — <task-name>

## Task Info

| Item | Content |
|---|---|
| Task name | <task-name> |
| Date | <YYYY-MM-DD> |
| Source | <user request verbatim or issue link> |
| Target function | `<FUNCTION_NAME>` (category: <string/temporal/...>) |

## Semantic Baseline

The function's doc card under `docs/gfvbot/shared/flink-expressions/` is the sole semantic baseline:

| Item | Content |
|---|---|
| Signature | `<FUNCTION(args)>` |
| Return type | <STRING/INT/...> |
| NULL behavior | <e.g. any NULL input yields NULL> |
| Boundary behavior | <e.g. out-of-range index returns NULL instead of raising> |
| Flink source anchor | see the "Source Location" section of the doc card |

## Goal and Scope

- Goal: <one sentence — the function works end to end on the GFV stack>
- In scope: <velox implementation + flinksql registration + gluten mapping + unit tests + e2e>
- Out of scope: <e.g. other members of the function family, performance tuning>

## Acceptance Criteria

1. Design passes the design audit (pass / fail)
2. Unit tests all pass per the design coverage matrix
3. e2e dual-run comparison (native Flink vs GlutenFlink) is exact for every SQL case
4. No regression on e2e cases of already-mapped expressions

## Verification Plan

| Layer | Method | Entry |
|---|---|---|
| velox unit tests | gtest covering the type matrix and NULL/boundary | flink-velox-unit-test skill |
| lightweight e2e | self-built input + print sink + verify script | implement-stage self-check |
| full e2e | dual-run the SQL list, exact compare after changelog reconstruction | flink-velox-e2e-verify skill |
