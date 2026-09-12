# SHA2

Category: [Hash](../index.md#hash) | Aliases: —

## Role and scenarios

SHA-2 digest of the chosen length — hashLength 224, 256, 384, or 512 (hex characters of the same count); 0 selects 256; other lengths are rejected. One spelling covering the whole SHA-2 family.

## Usage

Input: `SHA2(s, hashLength)` — s STRING, hashLength INT.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, SHA2(bid.extra, 256) FROM bid;
```

Output: STRING; 64 hex characters here (hashLength 256), data-dependent.

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| extra | SHA2(extra, 256) |
|---|---|
| A3F19C27B4E0 | 1683ce8b4f10d5996920d6b50c283e370b1f2d36bc310f7501707b190ebf4b90 |
| 8B2D4F90A1C3 | c8a6c2f6832233aa17dc4c298bee7d59e1bf364e839a7a2ade38175050edaf6d |
| C7E5A0D39F16 | b7bace464a3ce0a07adde2f4cacacf195a4073cddcc696d737b0f81da6071bf2 |
| ZK9M2Q7XVBT5 | 59b80c6d05771d1c3c76a5a84c9385a97f096a3eae570d2ff7656a8ad6e5f15f |
| D4C8B1E6A2F7 | 66d61b03455e9813b1f24a4e7470f70c18503ea19196d5c7a12c58807129938d |
| 5F0A9D3C7E8B | 409a801df9ae867309af325c178a3b4b01cd61dd9fcce693f780a56be5e4bbfe |
| ZZYYXXWWVVUU | 0e551d54c4146296d8d20bd28227c628489301a07c4a60b2c8f90e980f9661ec |
| E2B7F5A9C3D0 | f914a5388bc952a6a1ee6878c814f50971742cda3bb1e5922deaecc5c7f5e3e3 |

## Pipeline

The route of `SHA2` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.SHA2` (FlinkSqlOperatorTable.java:577).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:2100, registered under the name "sha2", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — StringCallGen generates direct calls into BuiltInMethods/StringUtils helpers; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
