# LOWER

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Converts a string to lowercase. Canonicalizing identifiers and keys before joins or dedup.

## Usage

Input: `LOWER(s)` — s of STRING/CHAR; NULL yields NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, LOWER(bid.extra) FROM bid;
```

Output: STRING; the 12-character value of `extra` lowercased, one value per row (data-dependent).

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| extra | LOWER(extra) |
|---|---|
| A3F19C27B4E0 | a3f19c27b4e0 |
| 8B2D4F90A1C3 | 8b2d4f90a1c3 |
| C7E5A0D39F16 | c7e5a0d39f16 |
| ZK9M2Q7XVBT5 | zk9m2q7xvbt5 |
| D4C8B1E6A2F7 | d4c8b1e6a2f7 |
| 5F0A9D3C7E8B | 5f0a9d3c7e8b |
| ZZYYXXWWVVUU | zzyyxxwwvvuu |
| E2B7F5A9C3D0 | e2b7f5a9c3d0 |

## Pipeline

The route of `LOWER` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.LOWER` (FlinkSqlOperatorTable.java:1182).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:780, registered under the name "lower", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — StringCallGen generates direct calls into BuiltInMethods/StringUtils helpers; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
