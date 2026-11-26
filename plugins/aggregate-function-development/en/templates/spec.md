# SPEC — <task-name>

> Fill section by section; write "none" for empty items, never delete a section.

## Task

- task-name:
- Date:
- Source: <task prompt or requirement origin>

## Feasibility assessment

- Existing and extensible aggregates on the velox C++ side: <function/class name and version, verified against sources or docs; write "to be verified" when it cannot be found>
- Type support and type matrix: <support and gaps for the target input types on the velox and Flink sides>
- Registration path: <where the flinksql-namespace aggregate registration lands; overwrite relationship with same-named prestosql entries>
- Batch integration point: <current state of the `makeAggregateInfos` aggregate facilities and RowContainer rows>
- Conclusion: `feasible` / `feasible with constraints` / `feasible with upstream dependency` / `not feasible`

## Goal and scope

- Goal: <one sentence on what the aggregate function must accomplish>
- In scope:
- Out of scope: <aggregate operators (GroupAggregator/WindowAggregator) are out of scope by default>

## Interface specification

- Function signature: <SQL function name, argument type matrix, return type>
- Registration entry: <namespace, registration file, entry shape>
- Cross-layer contract: <path from planner translation to runtime batch exposure>

## Behavior specification

- accumulate semantics: <per-row accumulation into the intermediate state>
- partial/merge semantics: <extracting and merging sharded intermediate results>
- finalize semantics: <intermediate state to the final output>
- NULL and empty set: <output for NULL inputs, all-NULL, and the empty set>
- Boundary behavior: <overflow, precision, very large cardinality>

## Acceptance criteria

- <Criterion 1: result consistency with native Flink on the same input>
- <Criterion 2: nexmark aggregate queries or existing unit tests that must not regress>
- <Criterion 3: full type-matrix coverage>

## Verification plan

- Unit tests: <test targets and the behaviors they pin (type matrix / NULL / partial round trips)>
- End-to-end: <dual-run cases and comparison baseline; start from nexmark q17, widen to q15/q16/q4 as the change dictates>
- Regression: <existing aggregates and shared aggregate facilities to re-check>
