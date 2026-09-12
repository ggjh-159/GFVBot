# OR

Category: [Logical](../index.md#logical) | Aliases: —

## Role and scenarios

Logical disjunction under three-valued logic: TRUE when either operand is TRUE; FALSE only when both are FALSE; otherwise UNKNOWN. Broadening filters and fallback conditions.

## Usage

Input: `a OR b` — both operands BOOLEAN; NULL combines per three-valued logic (`NULL OR TRUE` is TRUE).

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, (bid.auction > 15) OR (bid.bidder < 10) FROM bid;
```

Output: BOOLEAN; true where `auction > 15` or `bidder < 10` holds (data-dependent).

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| auction | bidder | (auction > 15) OR (bidder < 10) |
|---|---|---|
| 3 | 15 | FALSE |
| 19 | 7 | TRUE |
| 8 | 8 | TRUE |
| 1 | 42 | FALSE |
| 14 | 23 | FALSE |
| 7 | 2 | TRUE |
| 11 | 11 | FALSE |
| 20 | 36 | TRUE |

## Pipeline

The route of `OR` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — infix syntax; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.OR` (FlinkSqlOperatorTable.java:1097).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:411, registered under the name "or", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — Inlined by ExprCodeGenerator into plain Java operator code (ScalarOperatorGens); no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
