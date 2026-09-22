# SPEC — <task-name>

## Task

- task-name:
- date:
- source: <task prompt or request reference>

## Feasibility assessment

- velox C++ support for the target semantics: <operator / function names and versions>
- Flink-to-velox semantic match: <exact match / partial match / compensation required, with the gap>
- Reuse assessment: <existing code to reuse, extend, or newly build>
- Affected layers: <planner / runtime / velox experimental stateful / velox4j>
- Conclusion: `feasible` / `feasible with constraints` / `feasible with upstream dependency` / `not feasible`

## Goal and scope

- Goal: <one sentence on what the operator must do>
- In scope:
- Out of scope:

## Interface specification

- Operator / function surface: <names, input and output types>
- Configuration: <options and their defaults>
- Cross-layer contract: <what planner hands to runtime, what runtime hands to the bridge>

## Behavior specification

- Trigger and cadence: <when the operator fires, per record / per watermark / per timer>
- State access: <what state is read and written, key shape, lifetime>
- Watermark and timer semantics: <how watermarks advance the operator, timer behavior>
- Output: <emitted rows and their schema, ordering guarantees>
- Edge behavior: <empty input, nulls, late data, state size bounds>

## Acceptance criteria

- <criterion 1: verifiable statement, e.g. output equality against a named baseline>
- <criterion 2: queries or tests that must not regress>
- <criterion 3: state or performance bounds, if any>

## Verification plan

- Unit tests: <targets and the behaviors they pin>
- End-to-end: <queries or workloads to run, baseline to compare against>
- Regression: <shared components to re-check>
