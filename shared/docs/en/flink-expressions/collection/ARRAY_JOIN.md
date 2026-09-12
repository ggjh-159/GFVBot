# ARRAY_JOIN

Category: [Collection](../index.md#collection) | Aliases: —

## Role and scenarios

Joins the array elements into one string with the delimiter; NULL elements are skipped unless a nullReplacement is given; a NULL array yields NULL. Rendering tag lists for display or CSV-ish output.

## Usage

Input: `ARRAY_JOIN(arr, delimiter[, nullReplacement])` — arr ARRAY.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, ARRAY_JOIN(ARRAY['a','b'], '-') FROM bid;
```

Output: STRING; 'a-b' on every row.

Example (input -> output):

| Input | Output |
|---|
| ARRAY_JOIN(ARRAY['a','b'], '-') | a-b |

## Pipeline

The route of `ARRAY_JOIN` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; no dedicated FlinkSqlOperatorTable constant — the call is resolved through FunctionDefinitionOperatorTable, which adapts BuiltInFunctionDefinitions entries into SqlFunctions on the fly.
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:336, registered under the name "ARRAY_JOIN", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — BridgingSqlFunctionCallGen invokes eval() on the table-runtime class scalar/ArrayJoinFunction (flink-table-runtime, new-stack carrier).
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
