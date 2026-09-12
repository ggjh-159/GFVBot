# MD5

Category: [Hash](../index.md#hash) | Aliases: —

## Role and scenarios

128-bit MD5 digest of the string, rendered as 32 lowercase hex characters. Change detection, cache keys, fingerprinting — not collision-resistant enough for security use.

## Usage

Input: `MD5(s)` — s of STRING; returns 32-character STRING.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, MD5(bid.extra) FROM bid;
```

Output: STRING; 32 hex characters per row (data-dependent).

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| extra | MD5(extra) |
|---|---|
| A3F19C27B4E0 | 3391d976e274ac3c8b3987f29f4cfd90 |
| 8B2D4F90A1C3 | d2700e68ec3f4bf6ab516f28083fb04a |
| C7E5A0D39F16 | ffd94a91f55bebe588985be25c3d3edd |
| ZK9M2Q7XVBT5 | acba1453a0ecdcdeb60e6cd1ddd0f70d |
| D4C8B1E6A2F7 | 05c4ad9174cc98f55266ab0883c337b1 |
| 5F0A9D3C7E8B | 7aa3ea2eba7a655fea2c8e2610af726e |
| ZZYYXXWWVVUU | 83fd3f4384f97d588a344e76e0940f03 |
| E2B7F5A9C3D0 | af8edb2fd39e82bc68428cb9d71ef95f |

## Pipeline

The route of `MD5` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.MD5` (FlinkSqlOperatorTable.java:511).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:2052, registered under the name "md5", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — StringCallGen generates direct calls into BuiltInMethods/StringUtils helpers; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
