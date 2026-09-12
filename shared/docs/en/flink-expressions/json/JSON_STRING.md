# JSON_STRING

Category: [JSON](../index.md#json) | Aliases: —

## Role and scenarios

Serializes any SQL value — including nested rows and collections — into JSON text. The generic encoder direction of the JSON constructors.

## Usage

Input: `JSON_STRING(v)` — v of any type; returns STRING.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, JSON_STRING(ROW(1, 'a')) FROM bid;
```

Output: STRING; '[1,"a"]' on every row — the row serialized as a JSON array.

Example (input -> output):

| Input | Output |
|---|
| JSON_STRING(ROW(1, 'a')) | [1,"a"] |

## Pipeline

The route of `JSON_STRING` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; no dedicated FlinkSqlOperatorTable constant — the call is resolved through FunctionDefinitionOperatorTable, which adapts BuiltInFunctionDefinitions entries into SqlFunctions on the fly.
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:2296, registered under the name "JSON_STRING", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — Dedicated JsonStringCallGen — serializes the value tree via the planner's JSON serializer.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
