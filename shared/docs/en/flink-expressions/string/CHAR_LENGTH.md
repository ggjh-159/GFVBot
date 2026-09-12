# CHAR_LENGTH

Category: [String](../index.md#string) | Aliases: `CHARACTER_LENGTH`

## Role and scenarios

Number of characters (not bytes) in a string. Length validation, truncation logic, width checks.

## Usage

Input: `CHAR_LENGTH(s)` — s of STRING/CHAR; returns INT.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, CHAR_LENGTH(bid.extra) FROM bid;
```

Output: INT; 12 on every row (`extra` is generated at length 12).

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| extra | CHAR_LENGTH(extra) |
|---|---|
| A3F19C27B4E0 | 12 |
| 8B2D4F90A1C3 | 12 |
| C7E5A0D39F16 | 12 |
| ZK9M2Q7XVBT5 | 12 |
| D4C8B1E6A2F7 | 12 |
| 5F0A9D3C7E8B | 12 |
| ZZYYXXWWVVUU | 12 |
| E2B7F5A9C3D0 | 12 |

## Pipeline

The route of `CHAR_LENGTH` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.CHAR_LENGTH` (FlinkSqlOperatorTable.java:1179).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:752, registered under the name "charLength", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — StringCallGen generates direct calls into BuiltInMethods/StringUtils helpers; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
