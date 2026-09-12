# MULTIPLY

Category: [Arithmetic](../index.md#arithmetic) | Aliases: `*`

## Role and scenarios

Numeric multiplication. NULL propagates. Scaling quantities — exchange rates, unit prices by counts, weighted features.

## Usage

Input: `a * b` — numeric times numeric; DECIMAL precision/scale derived from the operands.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.auction * 3 FROM bid;
```

Output: BIGINT; `auction * 3` per row (data-dependent).

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| auction | auction * 3 |
|---|---|
| 3 | 9 |
| 19 | 57 |
| 8 | 24 |
| 1 | 3 |
| 14 | 42 |
| 7 | 21 |
| 11 | 33 |
| 20 | 60 |

## Pipeline

The route of `MULTIPLY` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — infix syntax; no dedicated FlinkSqlOperatorTable constant — the call is resolved through FunctionDefinitionOperatorTable, which adapts BuiltInFunctionDefinitions entries into SqlFunctions on the fly.
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1358, registered under the name "times", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — Inlined by ExprCodeGenerator into plain Java operator code (ScalarOperatorGens); no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
