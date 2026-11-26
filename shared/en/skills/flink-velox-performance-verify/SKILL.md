---
name: flink-velox-performance-verify
description: Replay the same nexmark query set on native Flink and GFV under a fixed benchmark (100M events, 50M tps, blackhole, p=1/4/8/16) and emit a GFV/native throughput-ratio and runtime report.
---

# Flink-velox performance verification

Replay one nexmark query set on both native Flink and GFV, and quantify the GFV/native performance ratio.

## When to use

Quantifying the performance gap between GFV and native: one query set runs once per stack, and the report gives the GFV-vs-native throughput ratio per query and parallelism.

The comparison target is native, not a pre-optimization GFV build — that build may not support the very operator being implemented, so the SQL cannot run at all and no ratio exists; native Flink always implements every query.

## Run matrix and hard rules

| Round | Build | pipeline.object-reuse | Notes |
|---|---|---|---|
| native r0 | native Flink | false | baseline one |
| native r1 | native Flink | true | baseline two; r0 to r1 only changes conf, no cluster restart |
| gfv r0 | GFV | false | **GFV must not run object-reuse=true — it crashes**; the script rejects it |

Fixed benchmark parameters (identical across stacks and rounds, or the numbers are not comparable):

- 100M events, 50M tps generation rate, blackhole sink (built into the query DDL).
- Parallelism sweeps p=1/4/8/16; within one level both stacks must run the same p.
- The script lands the parameters: nexmark.yaml is replaced whole by the skill's fixed copy (conf/nexmark-gfv.yaml), and parallelism.default plus pipeline.object-reuse are written into flink-conf — **the originals are restored automatically after the run** (also on failure or interrupt).
- Total slots (TM count x taskmanager.numberOfTaskSlots) must be >= p; the script blocks and points at the fix when it is not.

## Evidence tree: `e2e/perf/` at the project root, not per-task

Same principle as `e2e/{sql,data,out,verify}`: captures are run evidence and the report is the ruling evidence, both accrete across tasks, latest round refreshed in place:

```
e2e/perf/
  native/   qNN.p<P>.r0.out         native reuse=false metrics table (extracted from submit.log)
            qNN.p<P>.r1.out         native reuse=true metrics table
            *.submit.log            full runner output (written automatically next to the out file)
  gfv/      qNN.p<P>.r0.out         GFV metrics table (reuse=false only)
            *.submit.log
  REPORT.md                          GFV/native ratio report (refreshed in place)
```

## Procedure

1. Pick the query set: q0 (throughput baseline) plus the target queries; the full catalog and selection guide is docs/nexmark-queries.md.
2. Native round (r0 and r1, sweeping p): `bin/run-perf.sh native qNN <p> false e2e/perf/native/qNN.p<P>.r0.out`; for the reuse=true round pass true as the 4th arg and name the artifact r1.
3. Restart the cluster on the GFV build via flink-velox-build.
4. GFV round (r0 only, sweeping p): `bin/run-perf.sh gfv qNN <p> false e2e/perf/gfv/qNN.p<P>.r0.out`.
5. Archive the report: `bin/perf_report.py e2e/perf/native e2e/perf/gfv > e2e/perf/REPORT.md` (template at references/report-template.md, structure fixed); the agent fills the header placeholders (date, build ids, environment).

## Comparison standard

Data only, no mechanical verdict: per query and level the GFV/native throughput ratios (one column per reuse baseline) and runtimes; rows whose event counts disagree are marked not comparable with the reason. The conclusion is left to a human weighing the ratios against environment noise. A job must reach FINISHED before its metrics table counts.
