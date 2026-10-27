# DESIGN — <task-name>

> Fill in section by section; keep the heading of any section marked "none". This design enters implementation only after design review (pass/fail) approval and user gate 1 confirmation.
> Typography discipline (a review item; failing it returns the doc for re-layout): bullets first — one fact per bullet with a source anchor (`Class#method` plus the repo-relative path), each bullet at most two lines; no running prose paragraphs; conclusions carrying multiple rulings split into ruling lists; table cells hold facts and anchors only, never reasoning.
> Content discipline (a review item): core directions and key points only; the agent's searching, comparing, and thinking process is not design content.
> Implementation-contract baseline: `docs/gfvbot/shared/stateful-operator-implementation.md` — walk its contract-matching section item by item; that document's pitfall table is the mandatory checklist for §8 risks; cite its section names verbatim (Backend contract / Choosing a state handle / Step-by-step implementation / Pitfalls).
> Not-applicable convention: write "not applicable + a one-line reason", never delete the row, never leave it blank — reuse-oriented tasks hit this heavily.

## 1. Task and inputs

| Item | Content |
|---|---|
| Target operator | `<operator-name>` (Flink semantics map to `<StreamExecXxx>`) |
| SPEC | `tasks/<task-name>/architect/SPEC.md` |
| Implementation contract | `docs/gfvbot/shared/stateful-operator-implementation.md` |
| Reference operator | `GroupAggregator` (`velox/experimental/stateful/agg/`) |

## 2. Current-state survey

| Item | Conclusion | Evidence (path) |
|---|---|---|
| Planner dispatch today | whether `StatefulPlanner#transformStatefulOperators` already has a same-kind branch | `velox/experimental/stateful/StatefulPlanner.cpp` |
| Plan nodes today | node classes in `StatefulPlanNode.h` usable as reference | same directory |
| Gluten ExecNodes today | whether a shadow-override class already exists | `gluten-flink/planner/.../stream/` |
| Reusable facilities | <operator shell / KeySelector / handles / serializers> | |
| Semantic gap | <one sentence on the gap between Flink semantics and the velox status quo> | |

## 3. Contract matching (walk the implementation-contract doc item by item)

### 3.1 State handle selection

| Item | Value | Basis (contract doc, state-handle selection) |
|---|---|---|
| Handle | <Aggregating/Value/List/Map>State | |
| Namespace | <VoidNamespace / custom Namespace> | |
| Value shape | <RowContainer row / single value / vector / map> | |

### 3.2 Lifecycle pattern placement

- Stateless facilities built in `initialize()`: <e.g. aggregate functions via makeAggregateInfos>
- `initializeStateBackend()` six steps placement: <each step mapped to this operator's concrete objects>
- `addInput()` seven steps placement: <each step mapped to this operator's concrete actions; for changelog, state the +I/-U/+U trigger conditions>
- Iron-rule check: the Flink-side transformation stays **non-keyed**; state access goes only through the `HeapKeyedStateBackend` typed API (never the base-class factories or the legacy `StreamOperatorStateHandler` plane).

### 3.3 Planning and dispatch

- Plan node: velox node class `<XxxNode>` (`StatefulPlanNode.h`) plus the velox4j mirror class plus serde registration name `<the exact same name>`
- `KeyedStateSpec`: key channels `<channels>` and key types `<types>`
- Planner dispatch: essentials of the `transformXxxOperator` branch
- Gluten wiring: shadow override of `<StreamExecXxx>`, operator via `GlutenOneInputOperator`

## 4. Impacted modules and files

| Repo | File | Change |
|---|---|---|
| velox | `velox/experimental/stateful/StatefulPlanNode.h` | new node class plus the serde triple |
| velox | `velox/experimental/stateful/StatefulPlanner.cpp` | dispatch branch |
| velox | `velox/experimental/stateful/<dir>/<Operator>.h/.cpp` | new operator |
| velox | `velox/experimental/stateful/tests/<Test>.cpp` | unit tests |
| velox4j | `plan/<Node>.java` plus `stateful/KeyedStateSpec` | mirror class |
| gluten | `planner/.../StreamExec<Xxx>.java` | shadow override |

## 5. Execution and data flow

- Placement of every step input → probe → state resolution → business logic → changelog → output: <per the seven-step pattern, item by item, with anchors>
- Watermark handling: <default cascade / the reason to override `processWatermark`>
- Batch-boundary action: <when `advance()` reclaims>

## 6. Checkpoint semantics

- State entries and schema: <value schema per handle>
- Recovery constraints: <maxParallelism pinned; register-before-restore placement>

## 7. Test strategy

### 7.1 Unit-test matrix (model on the `GroupAggregatorTest` fixture)

| Case | Input | Expected | Coverage intent |
|---|---|---|---|
| appendOnly | | | no rowKind column |
| explicit INSERT | | | rowKind validation |
| mixed kinds | | | <supported kind combinations> |
| changelog assertions | | | +I/-U/+U firing and suppression |
| snapshot/restore round-trip | | | post-restore feed equivalence |
| rescale recovery | | | partial key-group ranges |

### 7.2 End-to-end

| Case | SQL / query | Input construction | Comparison baseline |
|---|---|---|---|
| | <nexmark qNN or hand-built SQL> | | <native Flink output / changelog-replay diff> |

## 8. Risks (checked against the contract pitfall table, one row per table entry)

| Pitfall (contract doc, pitfalls) | Applies? | Mitigation placement |
|---|---|---|
| Flink side declared keyed | | transformation non-keyed |
| setAllocator/setOffsets wiring timing | | |
| descriptor closure lifetime | | close() resets in reverse order |
| Legacy state API misuse | | typed API |
| maxParallelism drift | | pinned for the whole lifetime |
| Schema drift / register before restore | | |
| Key columns with complex types | | |
| Dead keys across checkpoints | | advance() at batch boundaries |

## 9. Deviations from the SPEC

<none / per item: what deviates + why + whether the SPEC needs updating>
