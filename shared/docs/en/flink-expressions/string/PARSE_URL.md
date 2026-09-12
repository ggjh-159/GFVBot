# PARSE_URL

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Extracts one part of a URL — PROTOCOL, HOST, PATH, QUERY, REF, AUTHORITY, or FILE; with a key argument it returns that single query parameter. Log and referer analysis.

## Usage

Input: `PARSE_URL(url, part[, key])` — url and part STRING, key STRING.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, PARSE_URL('http://h/p?a=1#f', 'QUERY', 'a') FROM bid;
```

Output: STRING; '1' on every row (the value of query parameter a).

Example (input -> output):

| Input | Output |
|---|
| PARSE_URL('http://h/p?a=1#f', 'QUERY', 'a') | 1 |

## Pipeline

The route of `PARSE_URL` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.PARSE_URL` (FlinkSqlOperatorTable.java:611).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1094, registered under the name "parseUrl", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — StringCallGen generates direct calls into BuiltInMethods/StringUtils helpers; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
