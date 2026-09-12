# JSON_OBJECT

Category: [JSON](../index.md#json) | Aliases: —

## Role and scenarios

Builds a JSON object from KEY VALUE pairs; NULL ON NULL keeps NULL values, ABSENT ON NULL drops them. Assembling event payloads from columns.

## Usage

Input: `JSON_OBJECT([k VALUE v, ...] [NULL ON NULL | ABSENT ON NULL])` — keys STRING literals.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, JSON_OBJECT('k' VALUE 42) FROM bid;
```

Output: STRING; '{"k":42}' on every row.

Example (input -> output):

| Input | Output |
|---|
| JSON_OBJECT('k' VALUE 42) | {"k":42} |

## Pipeline

The route of `JSON_OBJECT` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.JSON_OBJECT` (FlinkSqlOperatorTable.java:1249).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:2305, registered under the name "JSON_OBJECT", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — Dedicated JsonObjectCallGen.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
