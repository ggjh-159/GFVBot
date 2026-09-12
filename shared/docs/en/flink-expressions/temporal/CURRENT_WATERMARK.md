# CURRENT_WATERMARK

Category: [Temporal](../index.md#temporal) | Aliases: —

## Role and scenarios

Returns the current event-time watermark for the given rowtime attribute as TIMESTAMP_LTZ — NULL before any watermark has passed; over a plain non-rowtime column it always evaluates to NULL. Debugging watermark progress and building watermark-aware logic; in practice the column must be declared as an event-time attribute.

## Usage

Input: `CURRENT_WATERMARK(rowtime)` — rowtime must be a time attribute.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, CURRENT_WATERMARK(bid.dateTime) FROM bid;
```

Output: TIMESTAMP_LTZ or NULL; NULL on every row here — `dateTime` is not a rowtime attribute.

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| dateTime | CURRENT_WATERMARK(dateTime) |
|---|---|
| 2026-07-03 09:15:22.480 | NULL |
| 2026-07-05 10:41:07.123 | NULL |
| 2026-07-09 11:02:59.640 | NULL |
| 2026-07-03 13:27:44.005 | NULL |
| 2026-07-12 14:50:18.872 | NULL |
| 2026-07-07 15:33:51.309 | NULL |
| 2026-07-09 16:19:36.551 | NULL |
| 2026-07-11 17:44:29.918 | NULL |

## Pipeline

The route of `CURRENT_WATERMARK` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function CURRENT_WATERMARK(rowtime); no dedicated FlinkSqlOperatorTable constant — the call is resolved through FunctionDefinitionOperatorTable, which adapts BuiltInFunctionDefinitions entries into SqlFunctions on the fly.
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:2181, registered under the name "CURRENT_WATERMARK", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — ExprCodeGenerator special case — reads the current watermark of the input StreamRecord context.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
