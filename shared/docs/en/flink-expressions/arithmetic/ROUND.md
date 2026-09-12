# ROUND

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Rounds x to d decimal places (default 0) using half-up rounding for the common numeric types. Money display values and fixed-granularity statistics.

## Usage

Input: `ROUND(x, d)` or `ROUND(x)` — x numeric, d integer literal >= 0.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, ROUND(bid.price, 1) FROM bid;
```

Output: Decimal with 1 fractional digit per row, e.g. 55.67 becomes 55.7.

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| price | ROUND(price, 1) |
|---|---|
| 55.67 | 55.7 |
| 12.50 | 12.5 |
| 99.99 | 100.0 |
| 3.14 | 3.1 |
| 61.20 | 61.2 |
| 28.05 | 28.1 |
| 77.77 | 77.8 |
| 45.00 | 45.0 |

## Pipeline

The route of `ROUND` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.ROUND` (FlinkSqlOperatorTable.java:270).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1632, registered under the name "round", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — MethodCallGen on a FunctionGenerator-registered BuiltInMethods static helper; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
