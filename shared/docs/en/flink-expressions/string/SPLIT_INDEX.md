# SPLIT_INDEX

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Splits s by the delimiter and returns the 0-based index-th piece; an out-of-range or negative index yields NULL. Cheap field extraction from delimited strings.

## Usage

Input: `SPLIT_INDEX(s, delim, index)` — index INT, 0-based from the start.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, SPLIT_INDEX('a/b/c', '/', 1) FROM bid;
```

Output: STRING; 'b' on every row.

Example (input -> output):

| Input | Output |
|---|
| SPLIT_INDEX('a/b/c', '/', 1) | b |

## Pipeline

The route of `SPLIT_INDEX` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.SPLIT_INDEX` (FlinkSqlOperatorTable.java:451).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1187, registered under the name "splitIndex", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — StringCallGen generates direct calls into BuiltInMethods/StringUtils helpers; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
