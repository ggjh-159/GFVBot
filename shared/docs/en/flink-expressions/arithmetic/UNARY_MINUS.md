# UNARY_MINUS

Category: [Arithmetic](../index.md#arithmetic) | Aliases: `-x`

## Role and scenarios

Prefix negation of a numeric value. Sign-flipping measures for deltas that read better negative (losses, lateness).

## Usage

Input: `-x` — x of any numeric type; NULL stays NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, -bid.auction FROM bid;
```

Output: BIGINT; the negated `auction` per row.

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| auction | -auction |
|---|---|
| 3 | -3 |
| 19 | -19 |
| 8 | -8 |
| 1 | -1 |
| 14 | -14 |
| 7 | -7 |
| 11 | -11 |
| 20 | -20 |

## Pipeline

The route of `UNARY_MINUS` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — prefix -x; no dedicated FlinkSqlOperatorTable constant — the call is resolved through FunctionDefinitionOperatorTable, which adapts BuiltInFunctionDefinitions entries into SqlFunctions on the fly.
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1504, registered under the name "minusPrefix", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — Inlined by ExprCodeGenerator into plain Java operator code (ScalarOperatorGens); no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
