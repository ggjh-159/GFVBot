# NEQ

Category: [Comparison](../index.md#comparison) | Aliases: `<>`, `!=`

## Role and scenarios

Negated equality: TRUE when the operands differ; NULL on either side yields UNKNOWN. Used to exclude specific values and to detect changes when comparing two columns or a column against a literal.

## Usage

Input: `a <> b` (also writable `a != b`) — same comparability rules as `=`; NULL propagates to UNKNOWN.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.auction <> bid.bidder FROM bid;
```

Output: BOOLEAN; true where `auction` differs from `bidder` (data-dependent).

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| auction | bidder | auction <> bidder |
|---|---|---|
| 3 | 15 | TRUE |
| 19 | 7 | TRUE |
| 8 | 8 | FALSE |
| 1 | 42 | TRUE |
| 14 | 23 | TRUE |
| 7 | 2 | TRUE |
| 11 | 11 | FALSE |
| 20 | 36 | TRUE |

## Pipeline

The route of `NEQ` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — infix syntax; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.NOT_EQUALS` (FlinkSqlOperatorTable.java:1096).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:501, registered under the name "notEquals", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — Inlined by ExprCodeGenerator into plain Java operator code (ScalarOperatorGens); no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
