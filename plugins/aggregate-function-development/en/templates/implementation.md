# IMPLEMENTATION——<task-name>

> Implementation record. Refresh in place after every rework; before delivery all unit tests pass and code review has passed.
> Checklist items that do not apply are written as "not applicable + a one-line reason", never deleted.

## 1. Change list

List file by file, matching `DESIGN.md` §4 one to one:

| Repo | File | Change | Design item |
|---|---|---|---|
| velox | `velox/aggregate/<dir>/<Function>.h/.cpp` | new aggregate kernel | §3 |
| velox | <actual registration file of the flinksql namespace> | registration entry | §3 |
| velox | `velox/aggregate/<dir>/tests/<Test>.cpp` | unit tests | §5.1 |

Changes beyond the design impact list: <none / item by item with reasons (a critical code-review finding)>

## 2. Build and deployment

| Step | Command entry | Result | Log |
|---|---|---|---|
| Compile (never skip the C++ build) | flink-velox-build skill | <success/failure> | `tmp/<task-name>/logs/cmd-outputs/` |
| Deploy and cluster restart | same | <success/failure> | |

## 3. Unit tests

| Case group | Count | Passed | Failed |
|---|---|---|---|
| Type matrix, type by type | | | |
| NULL and empty set | | | |
| partial/merge round trip | | | |
| finalize output vs Flink | | | |

Mapping to the design's §5.1 matrix: <matched item by item / missing X, reason>

Failing-case handling: <none / item by item: reason, fix, or suspension reason>

## 4. Scenario self-check

- [ ] No existing aggregate implementation was rewritten (only additions or extensions)
- [ ] Registration lands only in the flinksql namespace
- [ ] Test SetUp registration order: prestosql baseline first, flinksql overwrite second
- [ ] All four of accumulate/partial/merge/finalize implemented, no missing link
- [ ] NULL and empty-set semantics consistent with Flink; unsupported items fail loud
- [ ] Full type-matrix coverage; unsupported types error explicitly rather than silently

## 5. General self-check

- [ ] Code matches the design, no out-of-scope changes
- [ ] No safety issues (null pointers / out-of-bounds / injection-style concatenation, etc.)
- [ ] Unit tests complete and all passing, runnable standalone
- [ ] flink-velox-format skill check passed (log: `tmp/<task-name>/logs/cmd-outputs/<file>`)
- [ ] No obviously simpler or more efficient alternative

## 6. Deviations from the design

<none / item by item: deviation + reason + whether DESIGN.md was updated or a SPEC change is needed>
