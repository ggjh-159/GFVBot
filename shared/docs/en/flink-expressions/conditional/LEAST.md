# LEAST

Category: [Conditional](../index.md#conditional) | Aliases: —

## Role and scenarios

Returns the least value among its arguments; if any argument is NULL the result is NULL. Capping values (e.g. limit a discount so it never exceeds a bound).

## Usage

Input: `LEAST(v1, v2, ...)` — two or more values of a common comparable type.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, LEAST(bid.auction, bid.bidder, 60) FROM bid;
```

Output: BIGINT; the minimum of `auction`, `bidder`, and the literal 60 per row.

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| auction | bidder | LEAST(auction, bidder, 60) |
|---|---|---|
| 3 | 15 | 3 |
| 19 | 7 | 7 |
| 8 | 8 | 8 |
| 1 | 42 | 1 |
| 14 | 23 | 14 |
| 7 | 2 | 2 |
| 11 | 11 | 11 |
| 20 | 36 | 20 |

## Pipeline

The route of `LEAST` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; no dedicated FlinkSqlOperatorTable constant — the call is resolved through FunctionDefinitionOperatorTable, which adapts BuiltInFunctionDefinitions entries into SqlFunctions on the fly.
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:606, registered under the name "LEAST", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — ExprCodeGenerator's BridgingSqlFunction case generateGreatestLeast inlines a value-chaining comparison; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
