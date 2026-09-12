# CURRENT_ROW_TIMESTAMP

Category: [Temporal](../index.md#temporal) | Aliases: —

## Role and scenarios

A TIMESTAMP_LTZ clock read per row at evaluation time — whereas CURRENT_TIMESTAMP is fixed per query. In Flink 1.19 it must be written with parentheses or the parser treats it as a column name. Ingestion-time stamping.

## Usage

Input: `CURRENT_ROW_TIMESTAMP()` — parentheses required; TIMESTAMP_LTZ.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, CURRENT_ROW_TIMESTAMP() FROM bid;
```

Output: TIMESTAMP_LTZ; freshly read for each row.

Example (input -> output):

| Input | Output |
|---|
| — | 2026-09-11 10:23:41.209 |

The output is re-drawn per row (non-deterministic); one draw shown.

## Pipeline

The route of `CURRENT_ROW_TIMESTAMP` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function, parentheses required; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.CURRENT_ROW_TIMESTAMP` (FlinkSqlOperatorTable.java:635).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1786, registered under the name "currentRowTimestamp", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — Marked non-deterministic, so the planner neither folds it nor moves it across operators.
4. **Codegen** — CurrentTimePointCallGen in row-level mode — reads the clock per row.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
