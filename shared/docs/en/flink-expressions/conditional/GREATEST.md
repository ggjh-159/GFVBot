# GREATEST

Category: [Conditional](../index.md#conditional) | Aliases: —

## Role and scenarios

Returns the greatest value among its arguments; if any argument is NULL the result is NULL. Cross-column normalization and clamping, e.g. enforcing a floor on a computed value.

## Usage

Input: `GREATEST(v1, v2, ...)` — two or more values of a common comparable type.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, GREATEST(bid.auction, bid.bidder, 7) FROM bid;
```

Output: BIGINT; the maximum of `auction`, `bidder`, and the literal 7 per row.

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| auction | bidder | GREATEST(auction, bidder, 7) |
|---|---|---|
| 3 | 15 | 15 |
| 19 | 7 | 19 |
| 8 | 8 | 8 |
| 1 | 42 | 42 |
| 14 | 23 | 23 |
| 7 | 2 | 7 |
| 11 | 11 | 11 |
| 20 | 36 | 36 |

## Pipeline

The route of `GREATEST` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; no dedicated FlinkSqlOperatorTable constant — the call is resolved through FunctionDefinitionOperatorTable, which adapts BuiltInFunctionDefinitions entries into SqlFunctions on the fly.
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:596, registered under the name "GREATEST", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — ExprCodeGenerator's BridgingSqlFunction case generateGreatestLeast inlines a value-chaining comparison; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
