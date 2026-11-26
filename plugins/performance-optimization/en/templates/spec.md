# SPEC — <task-name>

> Fill section by section; write "none" for empty items, never delete a section. Baseline ratios cite only the actual `e2e/perf/REPORT.md` artifact.

## Task

- task-name:
- Date:
- Source: <task prompt or requirement origin>

## Feasibility assessment

- Baseline measurability: <cluster slots >= highest parallelism level; both the native and GFV builds deployable; cluster restartable to switch builds>
- Target realism: <the magnitude of the gap between the target ratio and the baseline; known ceilings (e.g. the native reuse=true baseline)>
- Reuse assessment: <existing optimization techniques, configurations, or batch paths that can be reused>
- Impacted layers: <Java side (planner translation / data bridging) / JNI boundary (serialization / Arrow passthrough) / velox C++ side (operators / expressions / aggregate kernels)>
- Conclusion: `feasible` / `feasible with constraints` / `feasible with upstream dependency` / `not feasible`

## Goal and scope

- Goal: <one sentence on what the optimization must achieve>
- In scope:
- Out of scope: <feature development of new operators/functions is out of scope by default; state explicitly when tool-level profiling has no consolidated skill>

## Optimization target and baseline

- Query set: <q0 throughput baseline + target queries, selected per nexmark-queries.md>
- Fixed benchmark: <100M events, 50M tps, blackhole, p=1/4/8/16; native reuse false/true, GFV false only>
- Baseline ratios (citing the baseline round of `e2e/perf/REPORT.md`):

| Query | p | GFV/native(r0) | GFV/native(r1) |
|---|---|---|---|
| | | | |

## Targets and constraints

- Target ratio or gain: <a decidable value, e.g. GFV/native(r0) >= 0.80>
- Correctness constraint: <the query set yields identical folded result sets on native and GFV; no regression>
- Benchmark constraint: <parameters fixed across both stacks and all rounds; confs swapped in and restored by the skill, never hand-edited>
- Environment constraint: <machine, TM x slots, available time window>

## Acceptance criteria

- <Criterion 1: re-measured ratios reach the target>
- <Criterion 2: the query set's correctness regression is fully consistent>
- <Criterion 3: benchmark parameters untouched, all jobs FINISHED>

## Verification plan

- Ratio re-measurement: <same matrix re-run, REPORT.md refreshes>
- Correctness regression: <e2e dual runs of the query set with comparison baseline>
- Unit tests: <test targets for the production files the optimization touches>
