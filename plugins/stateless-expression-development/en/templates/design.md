# DESIGN — <task-name>

> Fill in section by section; keep headings of sections marked "none". Implementation starts only after this design passes the design audit (pass / fail).
> Typography discipline (audited; sub-standard typography goes back for re-layout): bullets first — one bullet per point, one fact per bullet, with a source anchor, at most two lines each; no running prose paragraphs; conclusions carrying multiple rulings split into a ruling list (one ruling per line); table cells hold facts and anchors only, no reasoning.
> Content discipline (audited): core directions and key points only; unnecessary information stays out — the agent's own search, comparison, and thinking process is not part of the design.

## 1. Task and Inputs

| Item | Content |
|---|---|
| Target function | `<FUNCTION(args)>` |
| SPEC | `tasks/<task-name>/architect/SPEC.md` |
| Semantic baseline | `docs/gfvbot/shared/flink-expressions/<category>/<FUNCTION>.md` |

## 2. velox Status Survey

Check the "velox implementation" section of the doc card first, then verify against velox source:

| Item | Conclusion | Evidence (file path) |
|---|---|---|
| Doc card says | <built-in / sparksql suite / GFV-owned / none yet> | doc card verbatim |
| Source check | <registered name and implementation file> | `velox/functions/...` |
| flinksql namespace status | <list of already-registered functions> | `velox/functions/flinksql/Register.cpp` |
| velox4j load chain | <how the FLINK preset loads the flinksql registration, and with what prefix> | `velox4j/src/main/cpp/.../Init.cc` |
| Reusable? | <reuse as is / same semantics but must move to flinksql / semantics differ, rewrite / no implementation> | see §3 |

**Iron rules**:

- The runtime path always registers under the flinksql namespace (`velox/functions/flinksql/`) — never reuse a spark/presto registration; spark/presto implementations serve as semantic and style references only.
- Expression implementations prefer reusing existing velox libraries/classes, including existing function implementations (when semantics match, the flinksql registration references them directly); the §4 "Reference" row must state what is reused; self-write only when reuse does not hold (no such facility, or the §3 semantic comparison diverges).
- Modifying existing expression implementations is forbidden — behavior, signature, and structure all stay untouched; divergent semantics go through extension or addition only (new overloads, new registration entries, new files); reusing existing code directly is allowed.

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

Conclusion (a ruling list, one ruling per line):

- <reuse / migrate / rewrite / new implementation> + one-line reason: <object and anchor>

## 4. flinksql Registration Design

| Item | Design |
|---|---|
| Registered name | `<name> under the flinksql prefix` |
| Implementation file | `velox/functions/flinksql/<File>.h/.cpp` |
| Registration | <registerFunction simple UDF / registerStatefulVectorFunction> |
| Signature list | <one line per type combination> |
| CMake | new entry in `velox/functions/flinksql/CMakeLists.txt` |
| Reference | `velox/functions/flinksql/RegexFunctions.h` (existing in-tree example) |

Implementation notes (one bullet group per function, at most two lines per bullet):

- `<function>` (`<signature>`)
  - Main path: <steps + anchors>
  - Error path: <illegal input → behavior + anchor>
  - Constant optimization: <if any; delete this line otherwise>

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

| ID | Scenario (pitfalls specific to this function: index base, match mode, precision, ...) | Expected behavior | Covering case |
|---|---|---|---|
| S1 | | | <unit-test / e2e case name> |

## 10. Risks

| Risk | Impact | Mitigation |
|---|---|---|
| | | |
