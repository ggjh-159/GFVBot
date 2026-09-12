# PROCTIME

Category: [Temporal](../index.md#temporal) | Aliases: —

## Role and scenarios

In a DDL it marks a processing-time attribute; inside a query `PROCTIME()` evaluates to the current processing time as TIMESTAMP_LTZ. TTL decisions, late-data handling, and processing-time temporal joins.

## Usage

Input: `PROCTIME()` — no arguments; in DDL: `AS PROCTIME()`.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, PROCTIME() FROM bid;
```

Output: TIMESTAMP_LTZ; the processing instant of each row.

Example (input -> output):

| Input | Output |
|---|
| — | 2026-09-11 10:23:41.209 |

The output is re-drawn per row (non-deterministic); one draw shown.

## Pipeline

The route of `PROCTIME` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — PROCTIME() — attribute marker in DDL, function in queries; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.PROCTIME` (FlinkSqlOperatorTable.java:158).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:2159, registered under the name "proctime", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — In a DDL it types a column as a processing-time attribute; a reference inside a query is rewritten to PROCTIME_MATERIALIZE to read the row's processing timestamp.
4. **Codegen** — ExprCodeGenerator special case — reads the StreamRecord timestamp of the current row.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
