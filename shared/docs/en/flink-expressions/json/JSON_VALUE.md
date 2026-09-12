# JSON_VALUE

Category: [JSON](../index.md#json) | Aliases: —

## Role and scenarios

Extracts the scalar at the SQL/JSON path and returns it as a string (or the RETURNING type); ON EMPTY / ON ERROR clauses decide what happens on a missing path or a type mismatch.

## Usage

Input: `JSON_VALUE(json, path [RETURNING t] [on empty/error])` — json STRING.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, JSON_VALUE('{"a": 1}', '$.a') FROM bid;
```

Output: STRING; '1' on every row — the numeric scalar rendered as text.

Example (input -> output):

| Input | Output |
|---|
| JSON_VALUE('{"a": 1}', '$.a') | 1 |

## Pipeline

The route of `JSON_VALUE` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.JSON_VALUE` (FlinkSqlOperatorTable.java:1247).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:2262, registered under the name "JSON_VALUE", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — Dedicated JsonValueCallGen (planner codegen/calls) with ON EMPTY/ON ERROR handling.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
