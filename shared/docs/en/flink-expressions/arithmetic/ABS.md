# ABS

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Absolute value of a numeric input. Distance-from-zero measures and normalizing signed deltas.

## Usage

Input: `ABS(x)` — numeric; result type follows the input.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, ABS(bid.auction - 30) FROM bid;
```

Output: BIGINT; `ABS(auction - 30)` per row (data-dependent).

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| auction | ABS(auction - 30) |
|---|---|
| 3 | 27 |
| 19 | 11 |
| 8 | 22 |
| 1 | 29 |
| 14 | 16 |
| 7 | 23 |
| 11 | 19 |
| 20 | 10 |

## Pipeline

The route of `ABS` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.ABS` (FlinkSqlOperatorTable.java:1189).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1382, registered under the name "abs", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — MethodCallGen on a FunctionGenerator-registered BuiltInMethods static helper; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
