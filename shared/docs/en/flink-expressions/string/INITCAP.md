# INITCAP

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Capitalizes the first letter of each whitespace-separated word and lowercases the rest. Turning raw names into display form.

## Usage

Input: `INITCAP(s)` — s of STRING.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, INITCAP('hello world') FROM bid;
```

Output: STRING; 'Hello World' on every row.

Example (input -> output):

| Input | Output |
|---|
| INITCAP('hello world') | Hello World |

## Pipeline

The route of `INITCAP` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.INITCAP` (FlinkSqlOperatorTable.java:1183).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:760, registered under the name "initCap", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — StringCallGen generates direct calls into BuiltInMethods/StringUtils helpers; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
