# EQ

Category: [Comparison](../index.md#comparison) | Aliases: `=`

## Role and scenarios

Compares two operands for equality and returns TRUE when they are equal; if either side is NULL the result is UNKNOWN (treated as not-matching by WHERE). The most-used predicate in SQL: equality filters, join conditions, and CASE branches.

## Usage

Input: `a = b` — both sides of any mutually comparable type (numeric, string, boolean, temporal); NULL on either side yields UNKNOWN.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.auction = bid.bidder FROM bid;
```

Output: BOOLEAN; one value per row, true where `auction` equals `bidder` (data-dependent).

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| auction | bidder | auction = bidder |
|---|---|---|
| 3 | 15 | FALSE |
| 19 | 7 | FALSE |
| 8 | 8 | TRUE |
| 1 | 42 | FALSE |
| 14 | 23 | FALSE |
| 7 | 2 | FALSE |
| 11 | 11 | TRUE |
| 20 | 36 | FALSE |

## Pipeline

The route of `EQ` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — infix syntax; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.EQUALS` (FlinkSqlOperatorTable.java:1085).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:456, registered under the name "equals", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — Inlined by ExprCodeGenerator into plain Java operator code (ScalarOperatorGens); no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
