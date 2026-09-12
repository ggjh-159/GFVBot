# OVERLAY

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Replaces the substring of s that starts at 1-based position n and spans m characters with r: `OVERLAY(s PLACING r FROM n FOR m)`. In-place patching of fixed-width segments.

## Usage

Input: `OVERLAY(s PLACING r FROM n [FOR m])` — n, m INT.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, OVERLAY(bid.extra PLACING '**' FROM 2 FOR 2) FROM bid;
```

Output: STRING; characters 2-3 of `extra` replaced by '**' — still 12 characters per row.

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| extra | OVERLAY(extra PLACING '**' FROM 2 FOR 2) |
|---|---|
| A3F19C27B4E0 | A**9C27B4E0 |
| 8B2D4F90A1C3 | 8**4F90A1C3 |
| C7E5A0D39F16 | C**A0D39F16 |
| ZK9M2Q7XVBT5 | Z**2Q7XVBT5 |
| D4C8B1E6A2F7 | D**B1E6A2F7 |
| 5F0A9D3C7E8B | 5**9D3C7E8B |
| ZZYYXXWWVVUU | Z**XXWWVVUU |
| E2B7F5A9C3D0 | E**F5A9C3D0 |

## Pipeline

The route of `OVERLAY` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — standard OVERLAY(s PLACING r FROM n FOR m); the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.OVERLAY` (FlinkSqlOperatorTable.java:1176).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:905, registered under the name "overlay", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — StringCallGen generates direct calls into BuiltInMethods/StringUtils helpers; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
