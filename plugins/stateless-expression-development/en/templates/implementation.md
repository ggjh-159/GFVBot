# IMPLEMENTATION — <task-name>

> Implementation record. Before delivery: all self-checks pass and the code audit passes.

## 1. Change List

File by file, mapping one-to-one to §4–§6 of `DESIGN.md`:

| Layer | File | Change | Design item |
|---|---|---|---|
| velox | `velox/functions/flinksql/<File>.h` | added | §4 |
| velox | `velox/functions/flinksql/Register.cpp` | registration entry | §4 |
| velox | `velox/functions/flinksql/CMakeLists.txt` | build entry | §4 |
| velox | `velox/functions/flinksql/tests/<Test>.cpp` | unit tests | §7 |
| gluten | `.../RexCallConverterFactory.java` | mapping entry | §5 |

Changes beyond the design impact list: <none / justify each — the code audit scrutinizes this row>

## 2. Build and Deployment

| Step | Command entry | Result | Log |
|---|---|---|---|
| Compile (never skip the C++ build) | flink-velox-build skill | <pass/fail> | `tmp/<task-name>/logs/cmd-outputs/` |
| Deploy (jars into `$FLINK_HOME/lib/`) | same skill | <pass/fail> | |
| Cluster restart | | <pass/fail> | |

## 3. Unit Tests

| Case group | Count | Pass | Fail |
|---|---|---|---|
| Basic function | | | |
| Type matrix | | | |
| NULL / boundary | | | |
| Special scenarios | | | |

Mapping to the design §7 matrix: <every entry matched / missing N, why>

Failed cases: <none / each: cause, fix or suspension reason (suspension requires audit approval)>

## 4. Lightweight e2e Self-check

Self-built input → runs on the GFV cluster → verified by script:

| Case | Input | Output | Verification | Result |
|---|---|---|---|---|
| Smoke SQL | | | <script/manual> | |

## 5. Self-check List

- [ ] Code matches the design; no out-of-scope changes
- [ ] No safety issues (null dereference / out-of-bounds / injected concatenation ...)
- [ ] Unit tests complete and all passing
- [ ] Code format passes (clang-format / the mvn equivalent)
- [ ] No obviously simpler or faster alternative was overlooked (self-check: redundancy, poor scalability, poor readability)
