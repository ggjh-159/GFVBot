# ENCODE

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Encodes string s into bytes with the given charset, returning VARBINARY. Preparing strings for byte-level functions.

## Usage

Input: `ENCODE(s, charset)` — charset e.g. 'utf-8'; returns VARBINARY.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, ENCODE(bid.extra, 'utf-8') FROM bid;
```

Output: VARBINARY; the 12 UTF-8 bytes of `extra` per row.

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| extra | ENCODE(extra, 'utf-8') |
|---|---|
| A3F19C27B4E0 | 413346313943323742344530 |
| 8B2D4F90A1C3 | 384232443446393041314333 |
| C7E5A0D39F16 | 433745354130443339463136 |
| ZK9M2Q7XVBT5 | 5A4B394D3251375856425435 |
| D4C8B1E6A2F7 | 443443384231453641324637 |
| 5F0A9D3C7E8B | 354630413944334337453842 |
| ZZYYXXWWVVUU | 5A5A59595858575756565555 |
| E2B7F5A9C3D0 | 453242374635413943334430 |

## Pipeline

The route of `ENCODE` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.ENCODE` (FlinkSqlOperatorTable.java:871).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1034, registered under the name "encode", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — StringCallGen generates direct calls into BuiltInMethods/StringUtils helpers; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
