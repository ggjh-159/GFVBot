# Unit testing across the three repos

Where tests live and how they run in velox (C++), velox4j (C++ + Java), and gluten-flink (Java) — and which layer a new test belongs to. Structural fact first: gluten-flink's planner and runtime modules carry **no** `src/test`; all their tests sit in the separate `ut` module. Velox keeps a `tests/` directory per module. velox4j tests on both sides of the language boundary, its Java tests depending on the embedded native build.

| Repo | Framework | Tests what | Run with |
|---|---|---|---|
| velox | gtest + ctest | functions, operators, serde | `make unittest` / `ctest -R` / test binary + `--gtest_filter` |
| velox4j | C++ gtest (embedded build) + JUnit4 | serde round-trips, query execution, the queue | `src/main/cpp/test.sh` / `mvn test` |
| gluten-flink | JUnit5 + flink-test-utils | expression mapping (pure), end-to-end (MiniCluster) | `mvn test -pl ut -Dtest=X` |

## velox: gtest + ctest

Layout convention: a `tests/` subdirectory per module, one `velox_<component>_test` target per module. A new test file joins the `add_executable` source list in that module's `tests/CMakeLists.txt`; link `${VELOX_TEST_LIBS}` (brings `gtest_main` — no hand-written main); `gtest_discover_tests` turns each `TEST_F` into its own ctest entry. The tree-wide switch is `VELOX_BUILD_TESTING` (default on).

Scalar-function tests use the `FunctionBaseTest` fixture (`velox/functions/lib/tests/FunctionBaseTest.h`): register the function under test in `SetUpTestCase` (`registerFunction<...>` or `registerStatefulVectorFunction`), then `evaluate("myfunc(C0, C1)", makeRowVector({...}))` and `assertEqualVectors` — the expression string doubles as SQL. Stateful-operator tests live in `velox/experimental/stateful/tests/`: construct a `StatefulTask`, feed `StreamRecord`s, assert on output elements.

```bash
cd <velox-build-dir>
make unittest                                  # everything (runs ctest)
ctest -R RepeatTest                            # by name
<path>/velox_functions_lib_test --gtest_filter=RepeatTest.repeat   # gdb-able
```

## velox4j: two languages, one build

C++ side: the build embeds velox; `VELOX4J_BUILD_TESTING=ON` turns on velox's test tree and mounts `src/main/cpp/test/` (targets like `velox4j_query_serde_test`; fixtures on `VectorTestBase`). The one-shot entry is `src/main/cpp/test.sh` (configure with testing on, build, `ctest -V` in `build/test`). The serde-test idiom: take a plan JSON (hand-written, or captured from the debug log — see [plan serialization](plan-serde.md)), `ISerializable::deserialize`, assert fields, re-serialize and compare.

Java side: JUnit4 under `src/test/java/io/github/zhztheplayer/velox4j/`. The load-bearing rule: initialization goes through `Velox4jTests.ensureInitialized()` (SPARK preset) or `ensureInitializedForFlink()` (FLINK preset), and **the preset cannot switch within one JVM** — the C++ global registries initialize once. The POM's surefire config therefore runs two executions: the default one excludes the Flink-preset tests; a separate forked execution runs only them. A new FLINK-preset test must land in its own surefire execution and call `ensureInitializedForFlink()`. The native library loads from the jar; no extra environment needed.

## gluten-flink: the ut module

Everything sits in `gluten-flink/ut/` (JUnit5 + flink-test-utils), packaged as `rexnode/`, `streaming/api/`, `table/`, `vectorized/`, `velox/`. Two shapes:

- **Pure unit tests** — the model is `rexnode/RexNodeConverterTest`: build RexNodes with `FlinkTypeFactory` + `FlinkRexBuilder`, run `RexNodeConverter#toTypedExpr`, assert the TypedExpr tree. Seconds-fast feedback for mapping changes ([expression mapping](expression-mapping.md)).
- **End-to-end** — on `GlutenStreamingTestBase` (Flink's StreamingTestBase with a MiniCluster inside). The key facility is `runAndCheck`: JNA `dup2` reroutes the process stdout into a pipe to **capture the print connector's native output** (which never passes through a Java collector — see [runtime execution](runtime-execution.md)) and diff it against expected rows. nexmark end-to-end uses `NexmarkTest` with an embedded Kafka source. FLINK preset initialization follows the same one-preset-per-JVM rule.

```bash
cd gluten/gluten-flink
mvn test -pl ut -am                              # the module and its reactor deps
mvn test -pl ut -Dtest=RexNodeConverterTest#testMod    # one method
```

Upstream CI clones velox4j and applies `gluten-flink/patches/fix-velox4j.patch` before running tests — when local runs disagree with CI, check that patch first.

## Where a new test goes

- velox function -> the module's `tests/` on `FunctionBaseTest` (`ctest -R MyFuncTest`)
- serde round-trip (new plan node) -> velox4j C++ tests: JSON -> deserialize -> assert -> re-serialize -> compare
- operator behavior -> `velox/experimental/stateful/tests/` on a hand-built StatefulTask
- mapping regression (new converter) -> `ut` `rexnode/` pure unit test
- end-to-end (new ExecNode override / chain behavior) -> `ut` on `GlutenStreamingTestBase`: create table, INSERT/SELECT via print, `runAndCheck` the rows

Layering rule of thumb: logic lockable by pure unit tests (mapping, serde) never gets an end-to-end test; end-to-end is reserved for behavior that needs Velox actually running (operator semantics, output channels) — MiniCluster tests are slow and fragile, keep their count down.

## Pitfalls

| Symptom | Cause | Fix |
|---|---|---|
| `cannot switch to X in the same JVM` | preset initialized differently earlier in the same fork | FLINK-preset tests belong in their own surefire execution |
| ut module fails to resolve classes | reactor deps not built | run with `-pl ut -am` |
| New C++ test never runs | source not in `add_executable`, or `VELOX_BUILD_TESTING` off | add to the source list; check the switch |
| Local test results differ from CI | CI carries `fix-velox4j.patch` | compare against the patch before debugging |
| e2e suite drags the build | too many MiniCluster cases | apply the layering rule; push logic down to pure tests |
