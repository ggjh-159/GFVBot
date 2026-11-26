# DESIGN——<task-name>

> Fill section by section; keep the heading of a section marked "none". Implementation may start only after this design passes review (pass/fail) and is confirmed at user gate 1.
> Typography discipline (review item, returned for re-layout when unmet): bullets first — one bullet per point, one fact each, with a source anchor (`Class#method` + repo-relative path), at most two lines per point; table cells hold facts and anchors only, never reasoning.
> Content discipline (review item): core direction and essentials only; the agent's searching, comparing, and thinking process is not design content.
> Evidence discipline (review item): every conclusion carries a one-line basis (source location / ruling date / precedent); "already exists / reusable" claims must be verified against sources.
> Not-applicable convention: write "not applicable + a one-line reason", never delete a row or leave it blank — reuse-heavy tasks hit this often.

## 1. Task and inputs

| Item | Content |
|---|---|
| Target function | `<SQL function name>` (Flink semantics correspond to `<Flink built-in / UDAF name>`) |
| Formula | <new aggregate> = <existing aggregate or base class> skeleton + <one sentence on the incremental dimension> |
| SPEC | `tasks/<task-name>/architect/SPEC.md` |
| Reference implementation | <existing velox aggregate class and path (e.g. a sibling aggregate in the same namespace)> |

## 2. Current-state survey

Three-stage honest grading — half-finished work (dead code / hard-coding / NYI) evidenced file:line; "already exists / zero change" claims may be written only after source verification:

| Stage | Grade (complete / half-finished / missing) | Evidence (path:line) |
|---|---|---|
| velox aggregate kernel (state of sibling `Aggregate` implementations) | | |
| Registration entries (state of `aggregate::flinksql::registerAggregateFunctions()`) | | |
| Batch integration (state of the `makeAggregateInfos` and RowContainer paths) | | |

Reuse dispositions — one disposition per facility; facilities not adopted are listed too, with reasons, so later readers do not re-investigate:

| Facility | Disposition (reuse directly / reuse with changes / build new / not adopted) | Notes (change points or rejection reason) |
|---|---|---|
| <sibling aggregate / intermediate-state type / serializer / registration framework / ...> | | |

Semantic gap: <one sentence on the gap between Flink aggregate semantics and the velox current state>

## 3. Plan

- Type matrix: <input type x support table, with the fail-loud policy for unsupported types>
- Intermediate-state layout: <the intermediate type accumulate produces; memory and alignment constraints>
- The chain: accumulate <per-row behavior>; partial <intermediate-result extraction>; merge <shard merging>; finalize <final output>
- NULL and empty-set semantics: <values aligned with Flink>
- Registration entry: <registration file and entry under the flinksql namespace; note on overwriting same-named prestosql entries>
- Batch integration point: <where and how it hooks into the existing aggregate facilities>

## 4. Impacted modules and files

| Repo | File | Change |
|---|---|---|
| velox | `velox/aggregate/<dir>/<Function>.h/.cpp` | new aggregate kernel |
| velox | <actual registration file of the flinksql namespace, filled from sources> | registration entry |
| velox | `velox/aggregate/<dir>/tests/<Test>.cpp` | unit tests |
| velox4j | <if involved, filled from sources; otherwise "not applicable"> | |
| gluten | <if involved, filled from sources; otherwise "not applicable"> | |

## 5. Test strategy

### 5.1 Unit-test matrix (fixture per the implementation contract doc's test section: prestosql baseline registration first, flinksql overwrite second)

| Case | Input | Expected | Coverage intent |
|---|---|---|---|
| Type matrix, type by type | | | one row per supported input type |
| NULL and empty set | | | all-NULL / empty set / partial NULL |
| partial/merge round trip | | | sharded intermediate results merge equivalently |
| finalize output | | | intermediate state to the final value |
| Flink semantics comparison | | | same input, same result |

### 5.2 End-to-end and regression

| Case | SQL/query | Input construction | Comparison baseline |
|---|---|---|---|
| | <nexmark q17 start → q15/q16/q4, or self-constructed SQL> | | <native Flink folded result set> |

## 6. Risks and pending decisions

| Risk | Impact | Mitigation |
|---|---|---|
| <unsupported types / intermediate-state bloat / same-named prestosql overwrite / precision and overflow> | | |

Pending decisions: <none — or item by item: self-contained background + plan comparison table (dimension x option, recommendation column marked "recommended") + recommendation + one-line basis>. Only choices affecting semantics or registration scope belong here; decisions are ruled item by item at user gate 1, and decided items are marked with date and conclusion and written back into this section.

Deviations from SPEC: <none / item by item: deviation + reason + whether the SPEC needs a write-back>
