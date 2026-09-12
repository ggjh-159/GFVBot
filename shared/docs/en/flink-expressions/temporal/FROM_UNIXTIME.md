# FROM_UNIXTIME

Category: [Temporal](../index.md#temporal) | Aliases: —

## Role and scenarios

Formats epoch seconds (BIGINT) as a timestamp string in the session time zone, optionally with a format pattern. Human-readable rendering of epoch columns.

## Usage

Input: `FROM_UNIXTIME(unixtime[, format])` — unixtime BIGINT; returns STRING.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, FROM_UNIXTIME(1760000000) FROM bid;
```

Output: STRING; 1760000000 renders as '2025-10-09 12:26:40' in UTC — the text follows the session zone (Asia/Shanghai gives '2025-10-09 20:26:40').

Example (input -> output):

| Input | Output |
|---|
| FROM_UNIXTIME(1760000000) | 2025-10-09 12:26:40 |
Note: rendered in the UTC session zone here.

## Pipeline

The route of `FROM_UNIXTIME` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.FROM_UNIXTIME` (FlinkSqlOperatorTable.java:666).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1864, registered under the name "fromUnixtime", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — MethodCallGen on a FunctionGenerator-registered BuiltInMethods static helper; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
