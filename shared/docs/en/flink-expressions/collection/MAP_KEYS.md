# MAP_KEYS

Category: [Collection](../index.md#collection) | Aliases: —

## Role and scenarios

Array of the map's keys, in iteration order. Enumerating dimensions and building group-by lists.

## Usage

Input: `MAP_KEYS(m)` — m MAP; returns ARRAY of the key type.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, MAP_KEYS(MAP['k1', 1, 'k2', 2]) FROM bid;
```

Output: ARRAY<STRING>; [k1, k2] on every row.

Example (input -> output):

| Input | Output |
|---|
| MAP_KEYS(MAP['k1', 1, 'k2', 2]) | [k1, k2] |

## Pipeline

The route of `MAP_KEYS` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; no dedicated FlinkSqlOperatorTable constant — the call is resolved through FunctionDefinitionOperatorTable, which adapts BuiltInFunctionDefinitions entries into SqlFunctions on the fly.
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:144, registered under the name "MAP_KEYS", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — BridgingSqlFunctionCallGen invokes eval() on the table-runtime class scalar/MapKeysFunction (flink-table-runtime, new-stack carrier).
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
