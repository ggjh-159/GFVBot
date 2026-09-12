# COALESCE

Category: [Conditional](../index.md#conditional) | Aliases: —

## Role and scenarios

Returns the first non-NULL argument (NULL only when all are NULL); all arguments must resolve to a common type. Fallback chains over optional columns.

## Usage

Input: `COALESCE(v1, v2, ...)` — two or more values of a common type.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, COALESCE(CAST(NULL AS STRING), bid.extra) FROM bid;
```

Output: STRING; `extra` itself — the first argument is NULL, so the second wins.

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| extra | COALESCE(NULL, extra) |
|---|---|
| A3F19C27B4E0 | A3F19C27B4E0 |
| 8B2D4F90A1C3 | 8B2D4F90A1C3 |
| C7E5A0D39F16 | C7E5A0D39F16 |
| ZK9M2Q7XVBT5 | ZK9M2Q7XVBT5 |
| D4C8B1E6A2F7 | D4C8B1E6A2F7 |
| 5F0A9D3C7E8B | 5F0A9D3C7E8B |
| ZZYYXXWWVVUU | ZZYYXXWWVVUU |
| E2B7F5A9C3D0 | E2B7F5A9C3D0 |

## Pipeline

The route of `COALESCE` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; no dedicated FlinkSqlOperatorTable constant — the call is resolved through FunctionDefinitionOperatorTable, which adapts BuiltInFunctionDefinitions entries into SqlFunctions on the fly.
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:208, registered under the name "COALESCE", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — BridgingSqlFunctionCallGen invokes eval() on the table-runtime class scalar/CoalesceFunction (flink-table-runtime, new-stack carrier).
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
