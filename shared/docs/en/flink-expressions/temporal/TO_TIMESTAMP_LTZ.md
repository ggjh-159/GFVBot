# TO_TIMESTAMP_LTZ

Category: [Temporal](../index.md#temporal) | Aliases: —

## Role and scenarios

Converts a raw epoch value with the given precision (0 seconds, 3 millis, 6 micros, 9 nanos) into TIMESTAMP WITH LOCAL TIME ZONE. Converting numeric epoch columns.

## Usage

Input: `TO_TIMESTAMP_LTZ(numeric, precision)` — numeric BIGINT, precision INT.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, TO_TIMESTAMP_LTZ(1760000000, 3) FROM bid;
```

Output: TIMESTAMP_LTZ; the instant 2025-10-09T12:26:40Z (epoch millis), rendered in the session zone.

Example (input -> output):

| Input | Output |
|---|
| TO_TIMESTAMP_LTZ(1760000000, 3) | 2025-10-09 12:26:40.000 |
Note: rendered in the UTC session zone here.

## Pipeline

The route of `TO_TIMESTAMP_LTZ` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.TO_TIMESTAMP_LTZ` (FlinkSqlOperatorTable.java:812).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1904, registered under the name "toTimestampLtz", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — MethodCallGen on a FunctionGenerator-registered BuiltInMethods static helper; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
