# JSON_QUERY

Category: [JSON](../index.md#json) | Aliases: —

## Role and scenarios

Extracts the JSON object or array at the path and returns it as JSON text; WRAPPER clauses control array wrapping of the result. Pulling sub-documents rather than scalars.

## Usage

Input: `JSON_QUERY(json, path [RETURNING t] [wrapper] [on empty/error])` — json STRING.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, JSON_QUERY('{"a": {"b": 1}}', '$.a') FROM bid;
```

Output: STRING; the sub-object '{"b": 1}' on every row.

Example (input -> output):

| Input | Output |
|---|
| JSON_QUERY('{"a": {"b": 1}}', '$.a') | {"b": 1} |

## Pipeline

The route of `JSON_QUERY` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.JSON_QUERY` (FlinkSqlOperatorTable.java:1248).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:2280, registered under the name "JSON_QUERY", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — MethodCallGen on a FunctionGenerator-registered BuiltInMethods static helper; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
