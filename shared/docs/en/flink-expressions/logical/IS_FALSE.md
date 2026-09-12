# IS_FALSE

Category: [Logical](../index.md#logical) | Aliases: —

## Role and scenarios

TRUE only when the input is exactly FALSE — UNKNOWN is kept distinct and yields FALSE here. When the difference between false and unknown matters (e.g. anti-joins, NOT semantics), this is the precise test.

## Usage

Input: `x IS FALSE` — x of BOOLEAN (possibly NULL); result is never NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, (bid.auction > 10 IS FALSE) FROM bid;
```

Output: BOOLEAN; true only where `auction > 10` is exactly false.

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| auction | auction > 10 IS FALSE |
|---|---|
| 3 | TRUE |
| 19 | FALSE |
| 8 | TRUE |
| 1 | TRUE |
| 14 | FALSE |
| 7 | TRUE |
| 11 | FALSE |
| 20 | FALSE |

## Pipeline

The route of `IS_FALSE` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — postfix IS FALSE; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.IS_FALSE` (FlinkSqlOperatorTable.java:1111).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:537, registered under the name "isFalse", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — Inlined by ExprCodeGenerator into plain Java operator code (ScalarOperatorGens); no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
