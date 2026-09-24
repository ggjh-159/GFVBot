# Expression mapping: from RexNode to Velox TypedExpr

How one expression — a WHERE predicate, a SELECT computation — travels from Flink's planner-internal `RexNode` tree to a Velox `TypedExpr` tree, and what a new function needs on each side. One sentence of semantics first: the Flink-name-to-Velox-name string mapping happens on the Flink side; the implementation is looked up by name on the Velox side; neither side has a fallback — a missing mapping or an unregistered function fails the query.

```text
Flink planner (gluten-flink)      velox4j (Java)               velox (C++)
RexNode tree                      TypedExpr tree               ITypedExpr tree
 |
 +-- RexLiteral  --\
 +-- RexInputRef ---\  RexNodeConverter#toTypedExpr
 +-- RexFieldAccess--/  (types via LogicalTypeConverter,
 +-- RexCall        /    literals via toVariant)
        |
        v
   RexCallConverterFactory
   key = Flink/Calcite operator name
   exactly one converter must match
        |                            |
        +--- name+params only -------+---- Serde -> JSON -> JNI ----> deserialize
             (CallTypedExpr carries no                                     |
              function metadata)                                          v
                                                          resolution at evaluation time:
                                                          simpleFunctions() / vector function
                                                          table, populated by initForFlink()
```

| Stage | Entry point | Question answered |
|---|---|---|
| 1 Dispatch | `RexNodeConverter#toTypedExpr` (gluten-flink planner, `rexnode/`) | which TypedExpr each RexNode subclass becomes |
| 2 Types | `LogicalTypeConverter` (gluten-flink **runtime**, shared with planner) | the Flink-to-velox4j type table |
| 3 Function mapping | `RexCallConverterFactory` + `RexCallConverter` implementations (gluten-flink planner, `rexnode/functions/`) | how a Flink function call becomes a Velox call, including dialect fixes |
| 4 Bridge | `TypedExpr` model + `Serde` (velox4j, `expression/`) | why new functions usually need zero velox4j change |
| 5 Registration | `initForFlink()` (velox4j `Init.cc`) + the two register.cpp files (velox) | where function implementations live and get registered |

## Stage 1: dispatch by RexNode subclass

| RexNode | TypedExpr | Note |
|---|---|---|
| `RexLiteral` | `ConstantTypedExpr` | value wrapped by `toVariant` (see below) |
| `RexInputRef` | `FieldAccessTypedExpr` | **by column name**, not index — the conversion context carries the upstream output column names |
| `RexFieldAccess` | nested `FieldAccessTypedExpr` | inner reference translated recursively |
| `RexCall` | via `RexCallConverterFactory` | stage 3 |
| anything else | throws | no silent degradation |

`toVariant` detail worth knowing: DECIMAL (and INTERVAL SECOND) literals with precision <= 18 encode as a `BigIntValue` of the unscaled value; above that as `HugeIntValue` (int128) — matching Velox's dual Decimal representation.

## Stage 2: the type table

`LogicalTypeConverter` matches the **exact** Flink `LogicalType` class. Representative rows:

| Flink type | velox4j type |
|---|---|
| BooleanType / IntType / BigIntType / DoubleType | Boolean / Integer / BigInt / Double |
| VarCharType / CharType | VarChar (CHAR normalizes to VARCHAR) |
| TimestampType / LocalZonedTimestampType | Timestamp (LTZ distinguished by session timezone config) |
| DecimalType(p,s) | Decimal(p,s) |
| DayTimeIntervalType | BigInt |
| RowType / ArrayType / MapType | Row / Array / Map (recursive) |

An unmatched type throws `Unsupported logical type` — new data types must add an entry here.

## Stage 3: the converter table

`RexCallConverterFactory` holds an immutable map: Flink operator name -> list of candidate converters. Selection builds each candidate and calls `isSuitable`; **exactly one** must match (multiple -> exception, zero -> exception with each candidate's reason). Names translate along the way: `+` -> `add` (separate numeric and decimal converters), `MOD` -> `remainder`, `CASE` -> `if`, `IS NOT NULL` -> `isnotnull`.

Two converter shapes:

- `DefaultRexCallConverter(veloxName)` — recursive translate of children, assemble `CallTypedExpr(returnType, params, veloxName)`. Right for signature-compatible functions; a new function is often one map entry.
- Custom converters (e.g. `SplitIndexRexCallConverter`) — repair dialect differences before assembly: split_index's Flink index is 0-based INT while Velox wants 1-based BIGINT; the separator may arrive as an ASCII code literal that must become a string.

## Stage 4: why velox4j usually needs nothing

`CallTypedExpr` is just `functionName + params`. It carries no function metadata, so it is generic over every function name; the name-polymorphic serde ([plan serialization](plan-serde.md)) already covers it. Only a genuinely new expression shape (a new special form) would need a new `TypedExpr` subclass plus registry entries on both sides.

## Stage 5: implementations and registration in velox

Evaluation resolves names against the function tables populated at native-library load: `initForFlink()` = `initForSpark()` (the full sparksql set) + `functions::flinksql::registerFunctions()` (dialect corrections on top — e.g. a `regexp_extract` that returns NULL on no match, where spark returns the empty string).

The BIGO extension point for custom UDFs is `velox/experimental/stateful/udf/Register.cpp`: `count_char`, `extract`, `split_index` register there. Simple-function idiom:

- `template <typename T> struct MyFunc { VELOX_DEFINE_FUNCTION_TYPES(T); ... }`
- `bool call(Result& out, const arg_type<In1>& a, ...)` — first parameter is the output; `arg_type<>` dereferences inputs; return false to mark the row NULL
- `registerFunction<MyFunc, Return, In1, In2>({"myfunc"})` — one struct can register several signatures

Vector functions (whole-column logic) go through `exec::registerStatefulVectorFunction` instead.

## Adding a new expression

Flink side (required, pick one):

1. Semantics-compatible -> one map entry: `Map.entry("MYFUNC", Arrays.asList(() -> new DefaultRexCallConverter("myfunc")))`.
2. Dialect differences -> custom converter extending `BaseRexCallConverter` (model: `SplitIndexRexCallConverter`), with an honest `isSuitable`.
3. The function must already exist in the Flink catalog (built-in or `CREATE FUNCTION`) — gluten maps existing RexCalls, it does not create functions. New data types add `LogicalTypeConverter` entries; new literal shapes add `toVariant` cases.

velox4j side: usually nothing (stage 4).

velox side (required): implement (prefer simple function), register on an `initForFlink()`-reachable path (BIGO UDFs: `experimental/stateful/udf/Register.cpp`; dialect fixes: `functions/flinksql/`), and test (see [unit testing](unit-testing.md); the converter side gets a `RexNodeConverterTest` case).

## Pitfalls

| Symptom | Cause | Fix |
|---|---|---|
| `Function not supported: X` at planning | no map entry for the Flink name | add the entry (or the custom converter) |
| `Multiple/No suitable converter found` | candidates' `isSuitable` ranges overlap or leave a gap | re-draw the split; selection demands exactly one |
| `Function X not registered` at execution (C++) | registration not reachable from `initForFlink()` | wire the register call into the chain |
| Wrong decimal literal values | precision > 18 literals must take the HugeInt path | check `toVariant`'s decimal branch |
| Column-not-found in Velox expressions | assumed index-based field access | field access is by name; the context must carry upstream column names |
