# SIMILAR

Category: [Comparison](../index.md#comparison) | Aliases: `SIMILAR TO`

## Role and scenarios

Matches against an SQL:1999 regular expression via `s SIMILAR TO pattern` — its syntax (character classes, quantifiers over % and _) is distinct from both LIKE wildcards and Java regex.

## Usage

Input: `s SIMILAR TO pattern` — both strings; returns BOOLEAN.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.extra SIMILAR TO '%[0-9A-F]%' FROM bid;
```

Output: BOOLEAN; true when `extra` contains at least one character in 0-9A-F (data-dependent).

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| extra | extra SIMILAR TO '%[0-9A-F]%' |
|---|---|
| A3F19C27B4E0 | TRUE |
| 8B2D4F90A1C3 | TRUE |
| C7E5A0D39F16 | TRUE |
| ZK9M2Q7XVBT5 | TRUE |
| D4C8B1E6A2F7 | TRUE |
| 5F0A9D3C7E8B | TRUE |
| ZZYYXXWWVVUU | FALSE |
| E2B7F5A9C3D0 | TRUE |

## Pipeline

The route of `SIMILAR` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — infix s SIMILAR TO pattern; no dedicated FlinkSqlOperatorTable constant — the call is resolved through FunctionDefinitionOperatorTable, which adapts BuiltInFunctionDefinitions entries into SqlFunctions on the fly.
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:798, registered under the name "similar", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — StringCallGen generates direct calls into BuiltInMethods/StringUtils helpers; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
