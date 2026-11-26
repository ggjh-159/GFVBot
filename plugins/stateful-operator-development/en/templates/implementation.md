# IMPLEMENTATION — <task-name>

> Implementation record. Refreshed in place after every rework round; before handoff all unit tests pass and code review is approved.
> Checklist items that do not apply are written as "not applicable + a one-line reason", never deleted.

## 1. Change list

File by file, matching `DESIGN.md` §4 one to one:

| Repo | File | Change | Design entry |
|---|---|---|---|
| velox | `velox/experimental/stateful/StatefulPlanNode.h` | node class plus the serde triple | §3.3 |
| velox | `velox/experimental/stateful/StatefulPlanner.cpp` | dispatch branch | §3.3 |
| velox | `velox/experimental/stateful/<dir>/<Operator>.h/.cpp` | new operator | §3.2 |
| velox | `velox/experimental/stateful/tests/<Test>.cpp` | unit tests | §7.1 |
| velox4j | `plan/<Node>.java` | mirror class | §3.3 |
| gluten | `planner/.../StreamExec<Xxx>.java` | shadow override | §3.3 |

Changes beyond the design impact list: <none / itemized justification (a critical finding for code review)>

## 2. Build and deployment

| Step | Command entry | Result | Log |
|---|---|---|---|
| Compile (never skip the C++ build) | flink-velox-build skill | <success/fail> | `tmp/<task-name>/logs/cmd-outputs/` |
| Deploy and cluster restart | same | <success/fail> | |

## 3. Unit tests

| Case group | Count | Pass | Fail |
|---|---|---|---|
| appendOnly/INSERT/mixed kinds | | | |
| changelog assertions | | | |
| snapshot/restore round-trip | | | |
| rescale recovery | | | |

Mapping to the design §7.1 matrix: <matched item by item / missing X, and why>

Failed-case handling: <none / per case: cause, fix or deferral reason>

## 4. Lightweight e2e self-check

| Case | Input | Output | Verification | Result |
|---|---|---|---|---|
| smoke SQL | | | <script/manual check> | |

## 5. Contract self-check (against the implementation-contract doc)

- [ ] Flink-side transformation stays non-keyed
- [ ] State access goes only through the `HeapKeyedStateBackend` typed API (no legacy-plane calls)
- [ ] AggregatingState setAllocator/setOffsets precede the first `rows()` and restore (delete this line for non-Aggregating handles)
- [ ] Unsupported rowKind fails loud, never silently dropped
- [ ] `keyedBackend_->advance()` at batch boundaries
- [ ] close() in reverse order: reset handles/backend/selector first, then call the base class
- [ ] Plan constraints pinned as CHECKs (output schema, unsupported semantics)

## 6. General self-check

- [ ] Code matches the design, no out-of-scope changes
- [ ] No security issues (null dereference / out-of-bounds / injected concatenation, etc.)
- [ ] Unit tests complete and all passing, each runnable standalone
- [ ] Code format passes
- [ ] No obviously simpler or more efficient alternative

## 7. Deviations from the design

<none / per item: what deviates + why + whether DESIGN.md was updated or a SPEC change is needed>
