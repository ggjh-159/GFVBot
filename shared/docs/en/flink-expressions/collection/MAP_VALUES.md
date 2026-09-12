# MAP_VALUES

Category: [Collection](../index.md#collection) | Aliases: —

## Role and scenarios

Array of the map's values, in iteration order. Unpacking measurements for aggregate functions.

## Usage

Input: `MAP_VALUES(m)` — m MAP; returns ARRAY of the value type.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, MAP_VALUES(MAP['k1', 1, 'k2', 2]) FROM bid;
```

Output: ARRAY<INT>; [1, 2] on every row.

Example (input -> output):

| Input | Output |
|---|
| MAP_VALUES(MAP['k1', 1, 'k2', 2]) | [1, 2] |

## Pipeline

The route of `MAP_VALUES` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; no dedicated FlinkSqlOperatorTable constant — the call is resolved through FunctionDefinitionOperatorTable, which adapts BuiltInFunctionDefinitions entries into SqlFunctions on the fly.
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:156, registered under the name "MAP_VALUES", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — BridgingSqlFunctionCallGen invokes eval() on the table-runtime class scalar/MapValuesFunction (flink-table-runtime, new-stack carrier).
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
