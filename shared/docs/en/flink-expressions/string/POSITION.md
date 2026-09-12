# POSITION

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

1-based position of the first occurrence of x in s; 0 when absent; NULL when either input is NULL. Standard SQL spelling is `POSITION(x IN s)`.

## Usage

Input: `POSITION(x IN s)` — string arguments; returns INT.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, POSITION('A' IN bid.extra) FROM bid;
```

Output: INT; index of the first 'A' in `extra`, 0 when absent (data-dependent).

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| extra | POSITION('A' IN extra) |
|---|---|
| A3F19C27B4E0 | 1 |
| 8B2D4F90A1C3 | 9 |
| C7E5A0D39F16 | 5 |
| ZK9M2Q7XVBT5 | 0 |
| D4C8B1E6A2F7 | 9 |
| 5F0A9D3C7E8B | 4 |
| ZZYYXXWWVVUU | 0 |
| E2B7F5A9C3D0 | 7 |

## Pipeline

The route of `POSITION` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — standard POSITION(x IN s); the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.POSITION` (FlinkSqlOperatorTable.java:1178).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:888, registered under the name "position", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — StringCallGen generates direct calls into BuiltInMethods/StringUtils helpers; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
