# ELEMENT

Category: [Collection](../index.md#collection) | Aliases: —

## Role and scenarios

Returns the sole element of a one-element array; an empty array yields NULL, and an array with more than one element is an error. Unwrapping known-single results such as subquery outputs.

## Usage

Input: `ELEMENT(arr)` — arr ARRAY.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, ELEMENT(ARRAY[bid.auction]) FROM bid;
```

Output: BIGINT; the value of `auction` per row.

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| auction | ELEMENT(ARRAY[auction]) |
|---|---|
| 3 | 3 |
| 19 | 19 |
| 8 | 8 |
| 1 | 1 |
| 14 | 14 |
| 7 | 7 |
| 11 | 11 |
| 20 | 20 |

## Pipeline

The route of `ELEMENT` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.ELEMENT` (FlinkSqlOperatorTable.java:1145).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1972, registered under the name "element", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — Inlined by ExprCodeGenerator's ELEMENT case (sole-element read with cardinality check).
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
