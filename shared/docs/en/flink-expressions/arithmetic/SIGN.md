# SIGN

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Sign of the input: -1, 0, or 1. Direction flags derived from signed values.

## Usage

Input: `SIGN(x)` — numeric; result follows the input's type.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, SIGN(bid.auction - 30) FROM bid;
```

Output: Sign of `auction - 30` per row: -1, 0, or 1 (data-dependent).

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| auction | SIGN(auction - 30) |
|---|---|
| 3 | -1 |
| 19 | -1 |
| 8 | -1 |
| 1 | -1 |
| 14 | -1 |
| 7 | -1 |
| 11 | -1 |
| 20 | -1 |

## Pipeline

The route of `SIGN` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.SIGN` (FlinkSqlOperatorTable.java:1207).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1624, registered under the name "sign", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — MethodCallGen on a FunctionGenerator-registered BuiltInMethods static helper; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
