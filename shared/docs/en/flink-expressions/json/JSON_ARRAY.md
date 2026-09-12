# JSON_ARRAY

Category: [JSON](../index.md#json) | Aliases: —

## Role and scenarios

Builds a JSON array from its arguments, with the same NULL ON NULL / ABSENT ON NULL choice for NULL elements. Collecting column values into a payload array.

## Usage

Input: `JSON_ARRAY([v, ...] [NULL ON NULL | ABSENT ON NULL])` — values of any type.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, JSON_ARRAY(1, 2, 'a') FROM bid;
```

Output: STRING; '[1,2,"a"]' on every row.

Example (input -> output):

| Input | Output |
|---|
| JSON_ARRAY(1, 2, 'a') | [1,2,"a"] |

## Pipeline

The route of `JSON_ARRAY` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.JSON_ARRAY` (FlinkSqlOperatorTable.java:1254).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:2341, registered under the name "JSON_ARRAY", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — Dedicated JsonArrayCallGen.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
