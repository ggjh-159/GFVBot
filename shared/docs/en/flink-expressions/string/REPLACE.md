# REPLACE

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Replaces every occurrence of search with replacement in s. Literal (non-regex) substitution — escaping is never needed.

## Usage

Input: `REPLACE(s, search, replacement)` — all string arguments.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, REPLACE(bid.extra, 'A', 'a') FROM bid;
```

Output: STRING; `extra` with each 'A' turned into 'a' (data-dependent).

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| extra | REPLACE(extra, 'A', 'a') |
|---|---|
| A3F19C27B4E0 | a3F19C27B4E0 |
| 8B2D4F90A1C3 | 8B2D4F90a1C3 |
| C7E5A0D39F16 | C7E5a0D39F16 |
| ZK9M2Q7XVBT5 | ZK9M2Q7XVBT5 |
| D4C8B1E6A2F7 | D4C8B1E6a2F7 |
| 5F0A9D3C7E8B | 5F0a9D3C7E8B |
| ZZYYXXWWVVUU | ZZYYXXWWVVUU |
| E2B7F5A9C3D0 | E2B7F5a9C3D0 |

## Pipeline

The route of `REPLACE` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.REPLACE` (FlinkSqlOperatorTable.java:437).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:844, registered under the name "replace", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — StringCallGen generates direct calls into BuiltInMethods/StringUtils helpers; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
