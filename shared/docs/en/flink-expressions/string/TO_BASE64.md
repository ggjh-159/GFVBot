# TO_BASE64

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Encodes s into its base64 text. Safe transport of arbitrary bytes through text channels.

## Usage

Input: `TO_BASE64(s)` — s of STRING; returns STRING.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, TO_BASE64(bid.extra) FROM bid;
```

Output: STRING; base64 of `extra`'s 12 bytes — 16 characters per row.

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| extra | TO_BASE64(extra) |
|---|---|
| A3F19C27B4E0 | QTNGMTlDMjdCNEUw |
| 8B2D4F90A1C3 | OEIyRDRGOTBBMUMz |
| C7E5A0D39F16 | QzdFNUEwRDM5RjE2 |
| ZK9M2Q7XVBT5 | Wks5TTJRN1hWQlQ1 |
| D4C8B1E6A2F7 | RDRDOEIxRTZBMkY3 |
| 5F0A9D3C7E8B | NUYwQTlEM0M3RThC |
| ZZYYXXWWVVUU | WlpZWVhYV1dWVlVV |
| E2B7F5A9C3D0 | RTJCN0Y1QTlDM0Qw |

## Pipeline

The route of `TO_BASE64` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.TO_BASE64` (FlinkSqlOperatorTable.java:720).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:999, registered under the name "toBase64", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — StringCallGen generates direct calls into BuiltInMethods/StringUtils helpers; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
