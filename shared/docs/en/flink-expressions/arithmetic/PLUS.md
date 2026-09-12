# PLUS

Category: [Arithmetic](../index.md#arithmetic) | Aliases: `+`

## Role and scenarios

Numeric addition; also valid between temporal types and intervals. NULL propagates. Ubiquitous in derived measures — the q1 shaping column `0.908 * price + 10` is itself a PLUS on top of a MULTIPLY.

## Usage

Input: `a + b` — numeric plus numeric (type widened per the Flink type system), or temporal plus interval.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.auction + bid.bidder FROM bid;
```

Output: BIGINT; `auction + bidder` per row (data-dependent).

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| auction | bidder | auction + bidder |
|---|---|---|
| 3 | 15 | 18 |
| 19 | 7 | 26 |
| 8 | 8 | 16 |
| 1 | 42 | 43 |
| 14 | 23 | 37 |
| 7 | 2 | 9 |
| 11 | 11 | 22 |
| 20 | 36 | 56 |

## Pipeline

The route of `PLUS` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — infix syntax; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.PLUS` (FlinkSqlOperatorTable.java:1098).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1224, registered under the name "plus", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — Inlined by ExprCodeGenerator into plain Java operator code (ScalarOperatorGens); no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
