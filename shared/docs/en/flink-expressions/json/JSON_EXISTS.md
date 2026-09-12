# JSON_EXISTS

Category: [JSON](../index.md#json) | Aliases: —

## Role and scenarios

TRUE when the SQL/JSON path locates at least one value in the document. Fast membership tests on JSON payloads.

## Usage

Input: `JSON_EXISTS(json, path)` — json STRING, path SQL/JSON path.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, JSON_EXISTS('{"a": 1}', '$.a') FROM bid;
```

Output: BOOLEAN; true on every row — path $.a exists.

Example (input -> output):

| Input | Output |
|---|
| JSON_EXISTS('{"a": 1}', '$.a') | TRUE |

## Pipeline

The route of `JSON_EXISTS` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.JSON_EXISTS` (FlinkSqlOperatorTable.java:1246).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:2240, registered under the name "JSON_EXISTS", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — MethodCallGen on a FunctionGenerator-registered BuiltInMethods static helper; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
