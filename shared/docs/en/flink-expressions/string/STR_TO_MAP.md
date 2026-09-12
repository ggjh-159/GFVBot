# STR_TO_MAP

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Parses s into a MAP using pairDelim between pairs and kvDelim between key and value. Turning serialized tag or param strings back into queryable maps.

## Usage

Input: `STR_TO_MAP(s[, pairDelim[, kvDelim]])` — delimiters STRING.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, STR_TO_MAP('a=1,b=2', ',', '=') FROM bid;
```

Output: MAP<STRING, STRING>; {a=1, b=2} on every row.

Example (input -> output):

| Input | Output |
|---|
| STR_TO_MAP('a=1,b=2', ',', '=') | {a=1, b=2} |

## Pipeline

The route of `STR_TO_MAP` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.STR_TO_MAP` (FlinkSqlOperatorTable.java:321).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1199, registered under the name "strToMap", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — StringCallGen generates direct calls into BuiltInMethods/StringUtils helpers; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
