# ARRAY_POSITION

Category: [Collection](../index.md#collection) | Aliases: —

## Role and scenarios

1-based index of the first occurrence of the value; 0 when absent; a NULL array yields NULL. Finding the rank of a known-good element.

## Usage

Input: `ARRAY_POSITION(arr, v)` — arr ARRAY; returns INT.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, ARRAY_POSITION(ARRAY[1,2,3], 2) FROM bid;
```

Output: INT; 2 on every row.

Example (input -> output):

| Input | Output |
|---|
| ARRAY_POSITION(ARRAY[1,2,3], 2) | 2 |

## Pipeline

The route of `ARRAY_POSITION` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; no dedicated FlinkSqlOperatorTable constant — the call is resolved through FunctionDefinitionOperatorTable, which adapts BuiltInFunctionDefinitions entries into SqlFunctions on the fly.
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:247, registered under the name "ARRAY_POSITION", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — BridgingSqlFunctionCallGen invokes eval() on the table-runtime class scalar/ArrayPositionFunction (flink-table-runtime, new-stack carrier).
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
