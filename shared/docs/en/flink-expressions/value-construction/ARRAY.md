# ARRAY

Category: [Value Construction](../index.md#value-construction) | Aliases: —

## Role and scenarios

Array constructor `ARRAY[v1, v2, ...]`; the elements unify to a common element type. Bundling columns into one array value for downstream array functions.

## Usage

Input: `ARRAY[v1, v2, ...]` — elements of a common type.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, ARRAY[bid.auction, bid.bidder, 99] FROM bid;
```

Output: ARRAY<BIGINT>; `[auction, bidder, 99]` per row.

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| auction | bidder | ARRAY[auction, bidder, 99] |
|---|---|---|
| 3 | 15 | [3, 15, 99] |
| 19 | 7 | [19, 7, 99] |
| 8 | 8 | [8, 8, 99] |
| 1 | 42 | [1, 42, 99] |
| 14 | 23 | [14, 23, 99] |
| 7 | 2 | [7, 2, 99] |
| 11 | 11 | [11, 11, 99] |
| 20 | 36 | [20, 36, 99] |

## Pipeline

The route of `ARRAY` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — ARRAY[..] constructor; no dedicated FlinkSqlOperatorTable constant — the call is resolved through FunctionDefinitionOperatorTable, which adapts BuiltInFunctionDefinitions entries into SqlFunctions on the fly.
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1963, registered under the name "array", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — Inlined by ExprCodeGenerator's ARRAY_VALUE_CONSTRUCTOR case into a GenericArrayData build.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
