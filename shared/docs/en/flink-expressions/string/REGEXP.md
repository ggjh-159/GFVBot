# REGEXP

Category: [String](../index.md#string) | Aliases: `RLIKE`

## Role and scenarios

Full-string match against a Java regular expression, function form `REGEXP(s, pattern)`. Note: the infix spelling `a REGEXP b` is rejected by the Flink 1.19 parser — call it as a function.

## Usage

Input: `REGEXP(s, pattern)` (alias `RLIKE(s, pattern)`) — Java regex semantics.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, REGEXP(bid.extra, '^[0-9A-F]+$') FROM bid;
```

Output: BOOLEAN; true when `extra` consists only of 0-9A-F characters (data-dependent).

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| extra | REGEXP(extra, '^[0-9A-F]+$') |
|---|---|
| A3F19C27B4E0 | TRUE |
| 8B2D4F90A1C3 | TRUE |
| C7E5A0D39F16 | TRUE |
| ZK9M2Q7XVBT5 | FALSE |
| D4C8B1E6A2F7 | TRUE |
| 5F0A9D3C7E8B | TRUE |
| ZZYYXXWWVVUU | FALSE |
| E2B7F5A9C3D0 | TRUE |

## Pipeline

The route of `REGEXP` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form only (the infix spelling is rejected by the 1.19 parser); the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.REGEXP` (FlinkSqlOperatorTable.java:602).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1156, registered under the name "regexp", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — StringCallGen generates direct calls into BuiltInMethods/StringUtils helpers; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
