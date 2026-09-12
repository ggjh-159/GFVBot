# IS_NOT_NULL

Category: [Comparison](../index.md#comparison) | Aliases: —

## Role and scenarios

The complement of IS NULL, likewise never returning UNKNOWN. Prefiltering rows before null-sensitive arithmetic or string functions.

## Usage

Input: `x IS NOT NULL` — any nullable type; the result itself is never NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, (bid.auction IS NOT NULL) FROM bid;
```

Output: BOOLEAN; true on every row here — `auction` is a NOT NULL column.

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| auction | auction IS NOT NULL |
|---|---|
| 3 | TRUE |
| 19 | TRUE |
| 8 | TRUE |
| 1 | TRUE |
| 14 | TRUE |
| 7 | TRUE |
| 11 | TRUE |
| 20 | TRUE |

## Pipeline

The route of `IS_NOT_NULL` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — postfix IS NOT NULL; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.IS_NOT_NULL` (FlinkSqlOperatorTable.java:1106).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:519, registered under the name "isNotNull", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — Inlined by ExprCodeGenerator into plain Java operator code (ScalarOperatorGens); no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
