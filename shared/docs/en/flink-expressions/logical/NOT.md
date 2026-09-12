# NOT

Category: [Logical](../index.md#logical) | Aliases: —

## Role and scenarios

Logical negation: TRUE becomes FALSE and vice versa; UNKNOWN stays UNKNOWN. Parenthesize the operand — precedence surprises are the classic bug with NOT.

## Usage

Input: `NOT a` — operand BOOLEAN; NULL remains NULL (unknown).

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, NOT (bid.auction > 5) FROM bid;
```

Output: BOOLEAN; the negation of `auction > 5` per row (data-dependent).

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| auction | NOT (auction > 5) |
|---|---|
| 3 | TRUE |
| 19 | FALSE |
| 8 | FALSE |
| 1 | TRUE |
| 14 | FALSE |
| 7 | FALSE |
| 11 | FALSE |
| 20 | FALSE |

## Pipeline

The route of `NOT` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — prefix NOT; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.NOT` (FlinkSqlOperatorTable.java:1116).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:424, registered under the name "not", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — Inlined by ExprCodeGenerator into plain Java operator code (ScalarOperatorGens); no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
