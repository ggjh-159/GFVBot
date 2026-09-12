# AND

Category: [Logical](../index.md#logical) | Aliases: —

## Role and scenarios

Logical conjunction under three-valued logic: TRUE only when both operands are TRUE; FALSE as soon as either is FALSE; otherwise UNKNOWN. The basic building block for compound WHERE, JOIN, and HAVING predicates.

## Usage

Input: `a AND b` — both operands BOOLEAN; NULL combines per three-valued logic (`NULL AND FALSE` is FALSE).

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, (bid.auction > 5) AND (bid.bidder < 40) FROM bid;
```

Output: BOOLEAN; true where `auction > 5` and `bidder < 40` both hold (data-dependent).

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| auction | bidder | (auction > 5) AND (bidder < 40) |
|---|---|---|
| 3 | 15 | FALSE |
| 19 | 7 | TRUE |
| 8 | 8 | TRUE |
| 1 | 42 | FALSE |
| 14 | 23 | TRUE |
| 7 | 2 | TRUE |
| 11 | 11 | TRUE |
| 20 | 36 | TRUE |

## Pipeline

The route of `AND` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — infix syntax; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.AND` (FlinkSqlOperatorTable.java:1079).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:398, registered under the name "and", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — Inlined by ExprCodeGenerator into plain Java operator code (ScalarOperatorGens); no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
