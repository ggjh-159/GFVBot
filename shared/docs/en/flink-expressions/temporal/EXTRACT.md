# EXTRACT

Category: [Temporal](../index.md#temporal) | Aliases: —

## Role and scenarios

Pulls out one datetime field — YEAR, QUARTER, MONTH, WEEK, DAY, DOY, DOW, HOUR, MINUTE, SECOND — as an integer. Grouping by time buckets and deriving calendar features.

## Usage

Input: `EXTRACT(field FROM ts)` — ts of DATE/TIME/TIMESTAMP (or interval); returns BIGINT.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, EXTRACT(DAY FROM bid.dateTime) FROM bid;
```

Output: BIGINT; day-of-month of `dateTime`, 1-31 per row (data-dependent).

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| dateTime | EXTRACT(DAY FROM dateTime) |
|---|---|
| 2026-07-03 09:15:22.480 | 3 |
| 2026-07-05 10:41:07.123 | 5 |
| 2026-07-09 11:02:59.640 | 9 |
| 2026-07-03 13:27:44.005 | 3 |
| 2026-07-12 14:50:18.872 | 12 |
| 2026-07-07 15:33:51.309 | 7 |
| 2026-07-09 16:19:36.551 | 9 |
| 2026-07-11 17:44:29.918 | 11 |

## Pipeline

The route of `EXTRACT` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — standard EXTRACT(field FROM ts); the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.EXTRACT` (FlinkSqlOperatorTable.java:1170).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1732, registered under the name "extract", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — ExtractCallGen on BuiltInMethods.UNIX_DATE_EXTRACT (timestamp-with-timezone variant via EXTRACT_FROM_TIMESTAMP_TIME_ZONE).
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
