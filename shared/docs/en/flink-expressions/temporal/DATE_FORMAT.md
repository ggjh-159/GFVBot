# DATE_FORMAT

Category: [Temporal](../index.md#temporal) | Aliases: —

## Role and scenarios

Formats a timestamp (or timestamp string) with a Java SimpleDateFormat-style pattern such as yyyy-MM-dd HH:mm:ss, returning a STRING. Fixed-width time labels for reports and partition columns.

## Usage

Input: `DATE_FORMAT(ts, pattern)` — ts TIMESTAMP/TIMESTAMP_LTZ/STRING, pattern STRING.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, DATE_FORMAT(bid.dateTime, 'yyyy-MM-dd HH:mm:ss') FROM bid;
```

Output: STRING; `dateTime` rendered per row in the given pattern (data-dependent).

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| dateTime | DATE_FORMAT(dateTime, 'yyyy-MM-dd HH:mm:ss') |
|---|---|
| 2026-07-03 09:15:22.480 | 2026-07-03 09:15:22 |
| 2026-07-05 10:41:07.123 | 2026-07-05 10:41:07 |
| 2026-07-09 11:02:59.640 | 2026-07-09 11:02:59 |
| 2026-07-03 13:27:44.005 | 2026-07-03 13:27:44 |
| 2026-07-12 14:50:18.872 | 2026-07-12 14:50:18 |
| 2026-07-07 15:33:51.309 | 2026-07-07 15:33:51 |
| 2026-07-09 16:19:36.551 | 2026-07-09 16:19:36 |
| 2026-07-11 17:44:29.918 | 2026-07-11 17:44:29 |

## Pipeline

The route of `DATE_FORMAT` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.DATE_FORMAT` (FlinkSqlOperatorTable.java:591).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1817, registered under the name "dateFormat", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — MethodCallGen on a FunctionGenerator-registered BuiltInMethods static helper; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
