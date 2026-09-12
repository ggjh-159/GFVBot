# DIVIDE

Category: [Arithmetic](../index.md#arithmetic) | Aliases: `/`

## Role and scenarios

Numeric division. Integer divided by integer returns DOUBLE — Flink never does truncating integer division; DECIMAL/DECIMAL returns a DECIMAL with derived precision. NULL propagates. Ratios and per-unit measures.

## Usage

Input: `a / b` — numeric divided by numeric; result DOUBLE for integer inputs, DECIMAL for decimal inputs.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.auction / 7 FROM bid;
```

Output: DOUBLE; `auction / 7` per row, e.g. 3 / 7 = 0.42857142857142855.

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| auction | auction / 7 |
|---|---|
| 3 | 0.42857142857142855 |
| 19 | 2.7142857142857144 |
| 8 | 1.1428571428571428 |
| 1 | 0.14285714285714285 |
| 14 | 2.0 |
| 7 | 1.0 |
| 11 | 1.5714285714285714 |
| 20 | 2.857142857142857 |

## Pipeline

The route of `DIVIDE` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — infix syntax; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.DIVIDE` (FlinkSqlOperatorTable.java:1082).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1337, registered under the name "divide", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — Inlined arithmetic (ScalarOperatorGens); DECIMAL division goes through the DivCallGen precision-preserving path.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
