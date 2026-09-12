# UNIX_TIMESTAMP

Category: [Temporal](../index.md#temporal) | Aliases: —

## Role and scenarios

Converts a timestamp string (with optional format) to epoch seconds in the session time zone; with no arguments it returns the current epoch seconds. Interop with unix-style APIs.

## Usage

Input: `UNIX_TIMESTAMP([s[, format]])` — s STRING; returns BIGINT.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, UNIX_TIMESTAMP('2026-09-11 10:00:00') FROM bid;
```

Output: BIGINT; epoch seconds of '2026-09-11 10:00:00' read in the session zone — 1789092000 under UTC+8.

Example (input -> output):

| Input | Output |
|---|
| UNIX_TIMESTAMP('2026-09-11 10:00:00') | 1789092000 |
Note: read in the UTC+8 session zone here.

## Pipeline

The route of `UNIX_TIMESTAMP` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — zero-arg or string form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.UNIX_TIMESTAMP` (FlinkSqlOperatorTable.java:645).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1877, registered under the name "unixTimestamp", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — The zero-argument form is a query-level constant; the string form is an ordinary per-row expression.
4. **Codegen** — MethodCallGen on a FunctionGenerator-registered BuiltInMethods static helper; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
