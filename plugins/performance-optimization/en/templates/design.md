# DESIGN——<task-name>

> Fill section by section; keep the heading of a section marked "none". Implementation may start only after this design passes review (pass/fail) and is confirmed at user gate 1.
> Typography discipline (review item, returned for re-layout when unmet): bullets first — one bullet per point, one fact each, with a source anchor (`Class#method` + repo-relative path), at most two lines per point; table cells hold facts and anchors only, never reasoning.
> Content discipline (review item): core direction and essentials only; the agent's searching, comparing, and thinking process is not design content.
> Evidence discipline (review item): every conclusion carries a one-line basis (ratio / web UI observation / source location); attribution without evidence does not stand.
> Not-applicable convention: write "not applicable + a one-line reason", never delete a row or leave it blank.

## 1. Task and inputs

| Item | Content |
|---|---|
| Optimization target | `<query/operator/expression name>` (one-sentence symptom, e.g. q17 GFV/native(r0)=0.55) |
| Goal | <the SPEC target ratio or gain> |
| SPEC | `tasks/<task-name>/architect/SPEC.md` |
| Baseline report | `e2e/perf/REPORT.md` (baseline round) |

## 2. Current state and localization evidence

Layered localization — every layer conclusion carries evidence (ratios, 8081 web UI backpressure / operator state / throughput-curve observations, source paths); "already exists / zero change" claims must be verified against sources:

| Layer | Observation (evidence) | Conclusion (bottleneck / not the bottleneck) |
|---|---|---|
| Java side (planner translation, data bridging) | | |
| JNI boundary (serialization, Arrow whole-batch passthrough) | | |
| velox C++ side (operators, expressions, aggregate kernels) | | |

Reuse dispositions — one disposition per facility or technique; techniques not adopted are listed too, with reasons:

| Facility / technique | Disposition (reuse directly / reuse with changes / build new / not adopted) | Notes (change points or rejection reason) |
|---|---|---|
| <existing configuration key / batch path / algorithm implementation / ...> | | |

## 3. Attribution and plan

- Attribution: <one sentence with the evidence chain: ratio → web UI observation → source path>
- Plan comparison:

| Plan | Expected gain | Risk | Change scope | Recommendation |
|---|---|---|---|---|
| <Plan A> | | | | <recommended / alternative> |
| <Plan B> | | | | |

- Selected plan essentials: <core changes and their expected point of action, with anchors>
- Semantics-unchanged guarantee: <the argument that the optimization does not change query results, and the matching regression cases>

## 4. Impacted modules and files

| Repo | File | Change |
|---|---|---|
| velox | `<path>` (filled from sources) | |
| velox4j | `<path>` (filled from sources; "not applicable" when untouched) | |
| gluten | `<path>` (filled from sources; "not applicable" when untouched) | |

## 5. Test strategy

### 5.1 Ratio re-measurement matrix (identical to the baseline)

| Query | p level | Rounds | Comparison |
|---|---|---|---|
| <qNN> | <1/4/8/16> | native r0/r1, gfv r0 | cell-by-cell against the baseline round of `e2e/perf/REPORT.md` |

### 5.2 Correctness regression and unit tests

| Case | SQL/query | Comparison baseline |
|---|---|---|
| | <SPEC query set: nexmark qNN or self-constructed> | <native Flink folded result set> |

Unit tests: <test targets for the production files the optimization touches, and the behaviors they pin>

## 6. Risks and pending decisions

| Risk | Impact | Mitigation |
|---|---|---|
| <semantic drift / environment noise / benchmark drift / tool-level profiling to be consolidated> | | |

Limitations list: <when tool-level profiling (perf/async-profiler/flamegraph) is needed but no consolidated skill exists in the repo, write "skill to be consolidated" + the question it must answer>

Pending decisions: <none — or item by item: self-contained background + plan comparison table (dimension x option, recommendation column marked "recommended") + recommendation + one-line basis>. Only choices affecting the optimization direction or the regression scope belong here; decisions are ruled item by item at user gate 1, and decided items are marked with date and conclusion and written back into this section.

Deviations from SPEC: <none / item by item: deviation + reason + whether the SPEC needs a write-back>
