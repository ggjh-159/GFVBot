# CARDINALITY

Category: [Collection](../index.md#collection) | Aliases: —

## Role and scenarios

Element count of an array or map; NULL input yields NULL. Size guards and per-element loop conditions.

## Usage

Input: `CARDINALITY(arr_or_map)` — ARRAY or MAP; returns INT.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, CARDINALITY(ARRAY[bid.auction, bid.bidder]) FROM bid;
```

Output: INT; 2 on every row.

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| auction | bidder | CARDINALITY(ARRAY[auction, bidder]) |
|---|---|---|
| 3 | 15 | 2 |
| 19 | 7 | 2 |
| 8 | 8 | 2 |
| 1 | 42 | 2 |
| 14 | 23 | 2 |
| 7 | 2 | 2 |
| 11 | 11 | 2 |
| 20 | 36 | 2 |

## Pipeline

The route of `CARDINALITY` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.CARDINALITY` (FlinkSqlOperatorTable.java:1152).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1951, registered under the name "cardinality", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — Inlined by ExprCodeGenerator's CARDINALITY case (array/map size read).
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
