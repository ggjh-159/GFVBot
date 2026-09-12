# REGEXP_REPLACE

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Replaces every substring of s that matches the Java regex with replacement. Masking digits, normalizing whitespace, rewriting log fragments.

## Usage

Input: `REGEXP_REPLACE(s, regex, replacement)` — java.util.regex semantics.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, REGEXP_REPLACE(bid.extra, '[0-9]', '#') FROM bid;
```

Output: STRING; `extra` with every digit replaced by '#' (data-dependent).

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| extra | REGEXP_REPLACE(extra, '[0-9]', '#') |
|---|---|
| A3F19C27B4E0 | A#F##C##B#E# |
| 8B2D4F90A1C3 | #B#D#F##A#C# |
| C7E5A0D39F16 | C#E#A#D##F## |
| ZK9M2Q7XVBT5 | ZK#M#Q#XVBT# |
| D4C8B1E6A2F7 | D#C#B#E#A#F# |
| 5F0A9D3C7E8B | #F#A#D#C#E#B |
| ZZYYXXWWVVUU | ZZYYXXWWVVUU |
| E2B7F5A9C3D0 | E#B#F#A#C#D# |

## Pipeline

The route of `REGEXP_REPLACE` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.REGEXP_REPLACE` (FlinkSqlOperatorTable.java:468).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1167, registered under the name "regexpReplace", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — StringCallGen generates direct calls into BuiltInMethods/StringUtils helpers; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
