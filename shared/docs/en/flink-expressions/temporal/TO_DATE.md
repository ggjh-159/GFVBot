# TO_DATE

Category: [Temporal](../index.md#temporal) | Aliases: —

## Role and scenarios

Parses a date string (default format yyyy-MM-dd) into a DATE. Converting text dates for date arithmetic and partitioning.

## Usage

Input: `TO_DATE(s[, format])` — s STRING; returns DATE.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, TO_DATE('2026-09-11') FROM bid;
```

Output: DATE; 2026-09-11 on every row.

Example (input -> output):

| Input | Output |
|---|
| TO_DATE('2026-09-11') | 2026-09-11 |

## Pipeline

The route of `TO_DATE` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.TO_DATE` (FlinkSqlOperatorTable.java:823).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1891, registered under the name "toDate", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — MethodCallGen on a FunctionGenerator-registered BuiltInMethods static helper; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
