# SHA1

Category: [Hash](../index.md#hash) | Aliases: —

## Role and scenarios

160-bit SHA-1 digest as 40 lowercase hex characters. Legacy fingerprinting — prefer the SHA-2 family for anything security-relevant.

## Usage

Input: `SHA1(s)` — s of STRING; returns 40-character STRING.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, SHA1(bid.extra) FROM bid;
```

Output: STRING; 40 hex characters per row (data-dependent).

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| extra | SHA1(extra) |
|---|---|
| A3F19C27B4E0 | 44efb9590ae04716b158b17ebdaf9e6bfa5c5dab |
| 8B2D4F90A1C3 | 3fde48eac4ceff69c20a7c0daa0467e1eba4ad1f |
| C7E5A0D39F16 | ae380e5be7cdd061963e6791bfa6968732657283 |
| ZK9M2Q7XVBT5 | c725c42b953ede1222cf7090f2f8bf1676e08fe4 |
| D4C8B1E6A2F7 | 12e227e4a5a9248aa8a94cbc89efa07e7f2e1ab2 |
| 5F0A9D3C7E8B | 7ca21ce9fbfd9c1b6e46f245b1f3541b8aa66180 |
| ZZYYXXWWVVUU | 503c53179981a96e0fa7a9c21bb00c9169fdea35 |
| E2B7F5A9C3D0 | 27d75fb52e892e24ee936a61ce4fee4bf5e17491 |

## Pipeline

The route of `SHA1` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.SHA1` (FlinkSqlOperatorTable.java:522).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:2060, registered under the name "sha1", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — StringCallGen generates direct calls into BuiltInMethods/StringUtils helpers; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
