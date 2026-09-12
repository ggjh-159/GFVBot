# TIMESTAMPDIFF

Category: [Temporal](../index.md#temporal) | Aliases: —

## Role and scenarios

Integer difference t2 minus t1 expressed in the given unit — SECOND, MINUTE, HOUR, DAY, MONTH, or YEAR (month/year differences are calendar-based). Latency, age, and duration computations.

## Usage

Input: `TIMESTAMPDIFF(unit, t1, t2)` — both temporal of a common kind; returns BIGINT.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, TIMESTAMPDIFF(SECOND, bid.dateTime, bid.dateTime) FROM bid;
```

Output: BIGINT; 0 on every row — the same timestamp stands on both sides.

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| dateTime | TIMESTAMPDIFF(SECOND, dateTime, dateTime) |
|---|---|
| 2026-07-03 09:15:22.480 | 0 |
| 2026-07-05 10:41:07.123 | 0 |
| 2026-07-09 11:02:59.640 | 0 |
| 2026-07-03 13:27:44.005 | 0 |
| 2026-07-12 14:50:18.872 | 0 |
| 2026-07-07 15:33:51.309 | 0 |
| 2026-07-09 16:19:36.551 | 0 |
| 2026-07-11 17:44:29.918 | 0 |

## Pipeline

The route of `TIMESTAMPDIFF` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.TIMESTAMP_DIFF` (FlinkSqlOperatorTable.java:1222).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1832, registered under the name "timestampDiff", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — TimestampDiffCallGen — calendar-aware unit arithmetic over the two temporals.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
