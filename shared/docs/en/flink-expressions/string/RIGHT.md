# RIGHT

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

The last n characters of s. Suffix extraction (file extensions, tail markers).

## Usage

Input: `RIGHT(s, n)` — n INT.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, RIGHT(bid.extra, 4) FROM bid;
```

Output: STRING; the last 4 characters of `extra` per row.

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| extra | RIGHT(extra, 4) |
|---|---|
| A3F19C27B4E0 | B4E0 |
| 8B2D4F90A1C3 | A1C3 |
| C7E5A0D39F16 | 9F16 |
| ZK9M2Q7XVBT5 | VBT5 |
| D4C8B1E6A2F7 | A2F7 |
| 5F0A9D3C7E8B | 7E8B |
| ZZYYXXWWVVUU | VVUU |
| E2B7F5A9C3D0 | C3D0 |

## Pipeline

The route of `RIGHT` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.RIGHT` (FlinkSqlOperatorTable.java:787).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1056, registered under the name "right", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — StringCallGen generates direct calls into BuiltInMethods/StringUtils helpers; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
