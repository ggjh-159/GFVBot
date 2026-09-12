# TEMPORAL_OVERLAPS

Category: [Temporal](../index.md#temporal) | Aliases: `OVERLAPS`

## Role and scenarios

Tests whether two time intervals share at least one instant: `(s1, e1) OVERLAPS (s2, e2)`; each side is a (start, end) pair or a (start, interval). Schedule-conflict detection and window-overlap checks.

## Usage

Input: `(s1, e1 | iv1) OVERLAPS (s2, e2 | iv2)` — endpoints temporal or start plus INTERVAL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, (bid.dateTime, INTERVAL '1' HOUR) OVERLAPS (bid.dateTime, INTERVAL '1' DAY) FROM bid;
```

Output: BOOLEAN; always true here — both windows start at `dateTime`, so the 1-hour one is contained in the 1-day one.

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| dateTime | (dateTime, 1h) OVERLAPS (dateTime, 1d) |
|---|---|
| 2026-07-03 09:15:22.480 | TRUE |
| 2026-07-05 10:41:07.123 | TRUE |
| 2026-07-09 11:02:59.640 | TRUE |
| 2026-07-03 13:27:44.005 | TRUE |
| 2026-07-12 14:50:18.872 | TRUE |
| 2026-07-07 15:33:51.309 | TRUE |
| 2026-07-09 16:19:36.551 | TRUE |
| 2026-07-11 17:44:29.918 | TRUE |

## Pipeline

The route of `TEMPORAL_OVERLAPS` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — infix (s1, e1) OVERLAPS (s2, e2); no dedicated FlinkSqlOperatorTable constant — the call is resolved through FunctionDefinitionOperatorTable, which adapts BuiltInFunctionDefinitions entries into SqlFunctions on the fly.
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1801, registered under the name "temporalOverlaps", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — SqlNode-to-Rex conversion expands OVERLAPS via TemporalOverlapsConverter (planner/expressions/converter/converters) into an AND/OR comparison tree over the interval bounds.
4. **Codegen** — Inlined by ExprCodeGenerator into plain Java operator code (ScalarOperatorGens); no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
