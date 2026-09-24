# DESIGN — <task-name>

> Fill in section by section; keep headings of sections marked "none". Implementation starts only after this design passes the design audit (pass / fail).

## 1. Task and Inputs

| Item | Content |
|---|---|
| Target function | `<FUNCTION(args)>` |
| SPEC | `tmp/<task-name>/architect/SPEC.md` |
| Semantic baseline | `docs/gfvbot/shared/flink-expressions/<category>/<FUNCTION>.md` |

## 2. velox Status Survey

Check the "velox implementation" section of the doc card first, then verify against velox source:

| Item | Conclusion | Evidence (file path) |
|---|---|---|
| Doc card says | <built-in / sparksql suite / GFV-owned / none yet> | doc card verbatim |
| Source check | <registered name and implementation file> | `velox/functions/...` |
| Reusable? | <reuse as is / same semantics but must move to flinksql / semantics differ, rewrite / no implementation> | see §3 |

**Iron rule**: whatever the survey concludes, the runtime path registers under the flinksql namespace (`velox/functions/flinksql/`) — never reuse a spark/presto registration. spark/presto implementations serve as semantic and style references only.

## 3. Semantic Comparison

Compare Flink semantics against the existing velox implementation (if any) dimension by dimension; any mismatch disqualifies direct reuse:

| Dimension | Flink semantics | Existing velox semantics | Match? |
|---|---|---|---|
| NULL handling | | | |
| Empty string / empty collection | | | |
| Out-of-range / illegal arguments | | | |
| Type matrix | | | |
| Return type and precision | | | |
| Function-specific dimensions (case, match mode, ...) | | | |

## 4. flinksql Registration Design

| Item | Design |
|---|---|
| Registered name | `<name> under the flinksql prefix` |
| Implementation file | `velox/functions/flinksql/<File>.h/.cpp` |
| Registration | <registerFunction simple UDF / registerStatefulVectorFunction> |
| Signature list | <one line per type combination> |
| CMake | new entry in `velox/functions/flinksql/CMakeLists.txt` |
| Reference | `velox/functions/flinksql/RegexFunctions.h` (existing in-tree example) |

## 5. gluten Mapping Design

| Item | Design |
|---|---|
| Mapping location | the `<FUNCTION>` entry in `RexCallConverterFactory` |
| Converter | <direct name mapping / custom converter (state the correction logic)> |
| Behavior when unmapped | expression conversion fails and the query errors (GFV has no fallback) — confirm this design removes that failure |

## 6. Implementation Plan

| Layer | Change | File |
|---|---|---|
| velox | <function implementation + registration + CMake> | |
| gluten | <mapping entry / converter> | |

## 7. Unit Test Coverage Matrix

| Case | Input | Expected | Intent |
|---|---|---|---|
| Basic function | | | |
| Each supported type | | | |
| NULL in each argument position | | | |
| Boundaries (empty / out-of-range / extremes) | | | |
| Special scenarios (see §9) | | | |

## 8. e2e Test Coverage Matrix

Every case is one SQL file (`e2e/sql/NNN_<intent>.sql` + fixed input data), all run on both ends:

| Case | SQL intent | Input construction | Changelog shape |
|---|---|---|---|
| Basic projection | | | append-only (+I only) |
| NULL rows | | | |
| Boundary values | | | |
| Combined / nested with other expressions | | | |
| Bounded aggregation context | | | retract stream (-U/+U) |

## 9. Special Scenarios

<list the pitfalls specific to this function: e.g. SPLIT_INDEX 0-based vs 1-based index, REGEXP full-string vs partial match, DECIMAL precision... each with the expected behavior and the case number that covers it>

## 10. Risks

| Risk | Impact | Mitigation |
|---|---|---|
| | | |
