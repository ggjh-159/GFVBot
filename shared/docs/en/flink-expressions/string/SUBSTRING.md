# SUBSTRING

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Extracts the substring of s starting at 1-based position n for m characters; without FOR m it runs to the end of the string. The canonical field-slicing expression.

## Usage

Input: `SUBSTRING(s FROM n [FOR m])` or `SUBSTRING(s, n [, m])` — n, m integer.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, SUBSTRING(bid.extra FROM 2 FOR 5) FROM bid;
```

Output: STRING; characters 2-6 of `extra` (5 characters) per row.

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| extra | SUBSTRING(extra FROM 2 FOR 5) |
|---|---|
| A3F19C27B4E0 | 3F19C |
| 8B2D4F90A1C3 | B2D4F |
| C7E5A0D39F16 | 7E5A0 |
| ZK9M2Q7XVBT5 | K9M2Q |
| D4C8B1E6A2F7 | 4C8B1 |
| 5F0A9D3C7E8B | F0A9D |
| ZZYYXXWWVVUU | ZYYXX |
| E2B7F5A9C3D0 | 2B7F5 |

## Pipeline

The route of `SUBSTRING` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — standard SUBSTRING(s FROM n FOR m); the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.SUBSTRING` (FlinkSqlOperatorTable.java:750).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:810, registered under the name "substring", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — StringCallGen generates direct calls into BuiltInMethods/StringUtils helpers; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
