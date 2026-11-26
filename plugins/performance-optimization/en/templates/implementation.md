# IMPLEMENTATION——<task-name>

> Implementation record. Refresh in place after every rework; before delivery all unit tests pass and code review has passed.
> Checklist items that do not apply are written as "not applicable + a one-line reason", never deleted.

## 1. Change list

List file by file, matching `DESIGN.md` §4 one to one:

| Repo | File | Change | Design item |
|---|---|---|---|
| velox | `<path>` | | §3 |
| velox4j | `<path>` | | §3 |
| gluten | `<path>` | | §3 |
| velox | `<tests/<Test>.cpp>` | unit tests | §5.2 |

Changes beyond the design impact list: <none / item by item with reasons (a critical code-review finding)>

## 2. Build and deployment

| Step | Command entry | Result | Log |
|---|---|---|---|
| Compile (never skip the C++ build) | flink-velox-build skill | <success/failure> | `tmp/<task-name>/logs/cmd-outputs/` |
| Deploy and cluster restart | same | <success/failure> | |

## 3. Unit tests

| Case group | Count | Passed | Failed |
|---|---|---|---|
| <test targets the change touches> | | | |

Mapping to the design's §5.2: <matched item by item / missing X, reason>

Failing-case handling: <none / item by item: reason, fix, or suspension reason>

## 4. Scenario self-check

- [ ] The optimization does not change query semantics — every change touching the result path has a matching regression case
- [ ] Changes stay within the plan and the impacted-file list; no drive-by refactoring
- [ ] Benchmark confs not hand-edited (the benchmark parameters in nexmark.yaml/flink-conf are managed by the skill); new runtime configuration goes through the regular configuration path and is recorded
- [ ] Performance-related configuration or batch-parameter changes are recorded in the §1 change list
- [ ] No object-reuse=true scheduled for the GFV round

## 5. General self-check

- [ ] Code matches the design, no out-of-scope changes
- [ ] No safety issues (null pointers / out-of-bounds / injection-style concatenation, etc.)
- [ ] Unit tests complete and all passing, runnable standalone
- [ ] flink-velox-format skill check passed (log: `tmp/<task-name>/logs/cmd-outputs/<file>`)
- [ ] No obviously simpler or more efficient alternative

## 6. Deviations from the design

<none / item by item: deviation + reason + whether DESIGN.md was updated or a SPEC change is needed>
