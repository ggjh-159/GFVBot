# TRUNCATE

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Cuts x off at d decimal places (default 0) with no rounding — the digits beyond d are simply dropped toward zero. When ROUND's half-up would overstate, TRUNCATE stays conservative.

## Usage

Input: `TRUNCATE(x, d)` or `TRUNCATE(x)` — x numeric, d integer literal >= 0.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, TRUNCATE(bid.price, 1) FROM bid;
```

Output: Decimal truncated at 1 fractional digit per row, e.g. 55.67 becomes 55.6.

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| price | TRUNCATE(price, 1) |
|---|---|
| 55.67 | 55.6 |
| 12.50 | 12.5 |
| 99.99 | 99.9 |
| 3.14 | 3.1 |
| 61.20 | 61.2 |
| 28.05 | 28.0 |
| 77.77 | 77.7 |
| 45.00 | 45.0 |

## Pipeline

The route of `TRUNCATE` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.TRUNCATE` (FlinkSqlOperatorTable.java:279).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1703, registered under the name "truncate", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — MethodCallGen on a FunctionGenerator-registered BuiltInMethods static helper; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
