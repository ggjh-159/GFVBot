# MAP

Category: [Value Construction](../index.md#value-construction) | Aliases: —

## Role and scenarios

Map constructor `MAP[k1, v1, k2, v2, ...]` — keys and values interleaved; keys and values each unify to their own common type. Small inline lookup tables.

## Usage

Input: `MAP[k1, v1, k2, v2, ...]` — keys of one type, values of one type.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, MAP['k1', bid.auction, 'k2', bid.bidder] FROM bid;
```

Output: MAP<STRING, BIGINT>; `{k1=auction, k2=bidder}` per row.

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| auction | bidder | MAP['k1', auction, 'k2', bidder] |
|---|---|---|
| 3 | 15 | {k1=3, k2=15} |
| 19 | 7 | {k1=19, k2=7} |
| 8 | 8 | {k1=8, k2=8} |
| 1 | 42 | {k1=1, k2=42} |
| 14 | 23 | {k1=14, k2=23} |
| 7 | 2 | {k1=7, k2=2} |
| 11 | 11 | {k1=11, k2=11} |
| 20 | 36 | {k1=20, k2=36} |

## Pipeline

The route of `MAP` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — MAP[k, v, ..] constructor; no dedicated FlinkSqlOperatorTable constant — the call is resolved through FunctionDefinitionOperatorTable, which adapts BuiltInFunctionDefinitions entries into SqlFunctions on the fly.
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1980, registered under the name "map", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — Inlined by ExprCodeGenerator's MAP_VALUE_CONSTRUCTOR case into a GenericMapData build.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
