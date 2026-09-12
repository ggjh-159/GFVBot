# IS_NULL

Category: [Comparison](../index.md#comparison) | Aliases: —

## Role and scenarios

Tests whether a value is NULL and returns plain TRUE or FALSE — never UNKNOWN — which makes it the only reliable null filter. Data-quality checks and guarding expressions that would otherwise propagate NULL.

## Usage

Input: `x IS NULL` — any nullable type; the result itself is never NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, (bid.auction IS NULL) FROM bid;
```

Output: BOOLEAN; false on every row here — `auction` is a NOT NULL column.

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| auction | auction IS NULL |
|---|---|
| 3 | FALSE |
| 19 | FALSE |
| 8 | FALSE |
| 1 | FALSE |
| 14 | FALSE |
| 7 | FALSE |
| 11 | FALSE |
| 20 | FALSE |

## Pipeline

The route of `IS_NULL` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — postfix IS NULL; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.IS_NULL` (FlinkSqlOperatorTable.java:1107).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:510, registered under the name "isNull", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — Inlined by ExprCodeGenerator into plain Java operator code (ScalarOperatorGens); no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
