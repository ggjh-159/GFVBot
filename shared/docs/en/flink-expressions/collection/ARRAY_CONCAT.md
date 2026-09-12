# ARRAY_CONCAT

Category: [Collection](../index.md#collection) | Aliases: —

## Role and scenarios

Concatenates two arrays keeping all elements (duplicates preserved). Appending batches of ids.

## Usage

Input: `ARRAY_CONCAT(a1, a2)` — arrays of a common element type.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, ARRAY_CONCAT(ARRAY[1,2], ARRAY[3]) FROM bid;
```

Output: ARRAY<INT>; [1, 2, 3] on every row.

Example (input -> output):

| Input | Output |
|---|
| ARRAY_CONCAT(ARRAY[1,2], ARRAY[3]) | [1, 2, 3] |

## Pipeline

The route of `ARRAY_CONCAT` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; no dedicated FlinkSqlOperatorTable constant — the call is resolved through FunctionDefinitionOperatorTable, which adapts BuiltInFunctionDefinitions entries into SqlFunctions on the fly.
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:316, registered under the name "ARRAY_CONCAT", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — BridgingSqlFunctionCallGen invokes eval() on the table-runtime class scalar/ArrayConcatFunction (flink-table-runtime, new-stack carrier).
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
