# REGEXP_EXTRACT

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Extracts the idx-th capture group of the first regex match (0 means the whole match); returns NULL when the pattern does not match. Pulling structured fields out of semi-structured strings.

## Usage

Input: `REGEXP_EXTRACT(s, regex[, idx])` — idx INT, default 1.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, REGEXP_EXTRACT(bid.extra, '([0-9A-F])', 1) FROM bid;
```

Output: STRING; the first captured 0-9A-F character, NULL on no match (data-dependent).

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| extra | REGEXP_EXTRACT(extra, '([0-9A-F])', 1) |
|---|---|
| A3F19C27B4E0 | A |
| 8B2D4F90A1C3 | 8 |
| C7E5A0D39F16 | C |
| ZK9M2Q7XVBT5 | 9 |
| D4C8B1E6A2F7 | D |
| 5F0A9D3C7E8B | 5 |
| ZZYYXXWWVVUU | NULL |
| E2B7F5A9C3D0 | E |

## Pipeline

The route of `REGEXP_EXTRACT` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.REGEXP_EXTRACT` (FlinkSqlOperatorTable.java:482).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:974, registered under the name "regexpExtract", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — StringCallGen generates direct calls into BuiltInMethods/StringUtils helpers; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
