# CURRENT_DATABASE

Category: [Auxiliary](../index.md#auxiliary) | Aliases: —

## Role and scenarios

Returns the name of the session's current database as a STRING. Templated SQL and environment-aware routing.

## Usage

Input: `CURRENT_DATABASE()` — no arguments; returns STRING.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, CURRENT_DATABASE() FROM bid;
```

Output: STRING; 'default_database' on every row.

Example (input -> output):

| Input | Output |
|---|
| — | default_database |

## Pipeline

The route of `CURRENT_DATABASE` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — zero-arg function; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.CURRENT_DATABASE` (FlinkSqlOperatorTable.java:1283).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1720, registered under the name "currentDatabase", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — StringCallGen's CURRENT_DATABASE case inlines the query-level database name via addReusableQueryLevelCurrentDatabase.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
