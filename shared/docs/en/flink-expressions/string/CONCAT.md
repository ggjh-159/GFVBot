# CONCAT

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Concatenates its arguments left to right; returns NULL if any argument is NULL. Assembling display strings and composite keys.

## Usage

Input: `CONCAT(s1, s2, ...)` — two or more string arguments.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, CONCAT(bid.extra, '-suffix') FROM bid;
```

Output: STRING; `extra` plus the literal '-suffix' — 19 characters per row.

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| extra | CONCAT(extra, '-suffix') |
|---|---|
| A3F19C27B4E0 | A3F19C27B4E0-suffix |
| 8B2D4F90A1C3 | 8B2D4F90A1C3-suffix |
| C7E5A0D39F16 | C7E5A0D39F16-suffix |
| ZK9M2Q7XVBT5 | ZK9M2Q7XVBT5-suffix |
| D4C8B1E6A2F7 | D4C8B1E6A2F7-suffix |
| 5F0A9D3C7E8B | 5F0A9D3C7E8B-suffix |
| ZZYYXXWWVVUU | ZZYYXXWWVVUU-suffix |
| E2B7F5A9C3D0 | E2B7F5A9C3D0-suffix |

## Pipeline

The route of `CONCAT` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.CONCAT_FUNCTION` (FlinkSqlOperatorTable.java:226).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:924, registered under the name "concat", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — StringCallGen generates direct calls into BuiltInMethods/StringUtils helpers; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
