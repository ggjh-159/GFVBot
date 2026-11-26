# Performance optimization quickstart

## Prerequisites

```bash
gfvbot install performance-optimization          # install the plugin (skills/docs/templates)
gfvbot clone                                     # clone the four repos into repos/
gfvbot env && gfvbot env-init                    # environment scan and completion
```

After installing (or reinstalling), start a **fresh session** in the project directory before running a task: agents load only at session start, so an already-open session cannot see the newly landed `.claude/agents/`; `/agents` listing the 5 `performance-*` agents means ready.

The first GFV build and cluster start are handled by the workflow: the implement stage runs the flink-velox-build skill to compile, deploy jars, and restart the cluster — no manual build before the task.

Benchmark environment first: the benchmark parameters (100M events, 50M tps, blackhole, p=1/4/8/16) are swapped into nexmark.yaml and flink-conf automatically by the flink-velox-performance-verify skill at run time and restored afterwards — do not hand-edit them; total cluster slots (TM count x taskmanager.numberOfTaskSlots) must be >= the task's highest parallelism level; the cluster is restarted on the other build between the native-Flink and GFV rounds via flink-velox-build. GFV runs object-reuse=false only (true crashes; the script rejects it).

## Example task: raising the GFV throughput ratio of nexmark q17 (q17-throughput)

A typical task — q17 (multi-aggregate grouped by seller) shows a low GFV/native throughput ratio; localize the bottleneck and optimize:

1. **SPEC**: the analyst runs the baseline via flink-velox-performance-verify (native r0/r1 and gfv r0 across parallelism levels), yielding the ratios in `e2e/perf/REPORT.md`; fill `spec.md` — optimization target and baseline ratios, target ratio, the no-regression constraint on the query set
2. **Design**: fill `design.md` — layered localization (ratios + 8081 web UI backpressure/operator state + internals map → attribute to the Java side / JNI boundary / velox C++ side, each with evidence), plan comparison table (gain x risk x change scope), impacted files, re-measurement matrix and regression set, risks and pending decisions
3. **SPEC/design review**: the reviewer issues pass/fail per `review-report.md` (baseline numbers must come from REPORT.md; attribution must have an evidence chain); after design approval, user gate 1 releases
4. **Implement**: optimize per the plan (compile and deploy via flink-velox-build, unit tests via flink-velox-unit-test); fill `implementation.md` (including the semantics-unchanged self-check); after code review pass, user gate 2 releases
5. **Verify**: performance-verify re-measures the ratios with the same matrix (REPORT.md refreshes) plus the e2e-verify correctness regression; fill `verify.md`; final acceptance plus user gate 3
6. **Retro**: PR.md, SUMMARY.md (with ratio changes and distillation suggestions); when upstream repos are touched, prepare drafts per the upstream-contribution templates and submit only after confirmation

## Workflow overview

| Stage | Owner | Gate | Key artifacts |
|---|---|---|---|
| spec | analyst | SPEC review pass | architect/SPEC.md, `e2e/perf/REPORT.md` (baseline) |
| design | analyst | design review pass + user gate 1 | architect/DESIGN.md |
| implement | developer | code review pass + user gate 2 | developer/IMPLEMENTATION.md |
| verify | verifier | final acceptance pass + user gate 3 | verifier/VERIFY.md, `e2e/perf/REPORT.md` (re-measurement) |
| retro | analyst | all artifacts archived | developer/PR.md, architect/SUMMARY.md |

Live task state is kept in `tasks/<task-name>/TASK_STATE.md` (shared template `docs/gfvbot/shared/templates/task-state.md`) and recovered from there after a session break; intra-stage progress shows in the `PROGRESS.md` heartbeat.

## Prompt template

`gfvbot prompt performance-optimization` prints the task template; `--task` has the AI fill it in.
