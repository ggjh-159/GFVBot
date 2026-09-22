---
name: flink-velox-unit-test
description: Run velox C++ unit tests through the skill's bin/run_velox_test.sh entry and gluten-flink Java tests through Maven, with focused target selection and failure-artifact collection.
---

# flink-velox-unit-test

## Purpose

Run unit tests across the two testable layers of the GFV stack, fast and focused:

- velox C++ tests: gtest targets under the velox repo's debug build
- gluten-flink Java tests: JUnit via Maven

## Entries

### velox C++ tests

```bash
bash bin/run_velox_test.sh <test_target> [gtest_filter]
```

Run `bin/run_velox_test.sh` relative to this skill's directory (or invoke it by absolute path from anywhere under the workspace). The script locates the workspace env archive `.gfvbot/env.json` (produced by `gfvbot env`, extended by `gfvbot clone`) on its own, handles the cmake/ctest configuration, reuses the dependency cache downloaded by the velox4j build, and rebuilds incrementally — re-running only recompiles changed files. Example targets follow the `velox_<component>_test` naming of the velox tree.

### gluten-flink Java tests

```bash
cd "$GLUTEN_FLINK_PATH" && mvn test -pl ut -am
```

The `-am` flag builds the reactor dependencies so the parent POM and upstream modules resolve. Narrow with `-Dtest=ClassName` or `-Dtest=ClassName#method` when focusing on one change.

## Discipline

- Run velox C++ tests only through this skill's `bin/run_velox_test.sh`; hand-written cmake, build, or ctest invocations miss dependency configuration and produce failures that say more about the invocation than the code.
- Run the narrowest test that covers the change first; widen to the full target only on green or when the reviewer asks for the suite.
- Order a full pass as velox4j (native included) before gluten-flink when both layers changed.
- Collect failure artifacts next to the report: `hs_err_pid*.log`, `core.*`, Surefire `*.dumpstream`, and the test-report XMLs. They are the input for the next debugging step.
- Test code follows the project's own conventions: `testXxx` method prefixes, minimal comments — tests document behavior through their names and assertions.
