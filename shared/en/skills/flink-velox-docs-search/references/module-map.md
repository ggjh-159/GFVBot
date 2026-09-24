# GFV repo module map

Repos live under `<workspace>/repos/`, laid down by `gfvbot clone` at the GFV baseline branches.

## repos/velox — velox C++ engine (branch gluten-20260829)

| Path | Responsibility |
|---|---|
| `velox/exec/` | batch execution: operators, HashTable, RowContainer, aggregates |
| `velox/experimental/stateful/` | streaming stateful extension: StatefulOperator, keyed operators, window aggregators, state backends under `state/` |
| `velox/experimental/connectors/` | streaming connectors (nexmark) |
| `velox/expression/` | expression evaluation: functions, binders, vector readers |
| `velox/type/`, `velox/vector/` | type system and vectors (Arrow-backed) |
| `velox/common/`, `velox/core/` | memory, config, primitives |
| `_build/debug/` | debug build tree where unit tests run |

## repos/velox4j — Java/JNI bridge (branch gluten-20260829)

| Path | Responsibility |
|---|---|
| `src/main/java/` | Java API wrapping velox plans, expressions, and data |
| `src/main/cpp/` | JNI native side, including the dependency cache reused by velox test builds |

## repos/gluten — gluten integration (branch main)

| Path | Responsibility |
|---|---|
| `gluten-flink/planner/` | Flink plan → velox plan translation |
| `gluten-flink/runtime/` | operator execution, state integration, arrow bridging |
| `gluten-flink/loader/` | session, library loading, jar bootstrap |
| `gluten-flink/ut/` | JUnit test module |
| `gluten-flink/patches/` | carried patches |

## repos/flink — Flink source (branch release-1.19)

Reference for operator semantics, state backends, and planner behavior. Read for comparison; the shipped runtime is the official distribution installed under `$FLINK_HOME`.
