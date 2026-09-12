# ROW

Category: [Value Construction](../index.md#value-construction) | Aliases: —

## Role and scenarios

Row constructor `ROW(v1, v2, ...)` building an anonymous composite value with fields f0, f1, ... (rename them with AS). Packaging heterogeneous values that travel together.

## Usage

Input: `ROW(v1, v2, ...)` — fields may differ in type.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, ROW(1, 'a', bid.auction) FROM bid;
```

Output: ROW<INT, STRING, BIGINT>; `(1, 'a', auction)` per row.

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| auction | ROW(1, 'a', auction) |
|---|---|
| 3 | (1, a, 3) |
| 19 | (1, a, 19) |
| 8 | (1, a, 8) |
| 1 | (1, a, 1) |
| 14 | (1, a, 14) |
| 7 | (1, a, 7) |
| 11 | (1, a, 11) |
| 20 | (1, a, 20) |

## Pipeline

The route of `ROW` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — ROW(..) constructor; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.ROW` (FlinkSqlOperatorTable.java:1156).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1989, registered under the name "row", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — Inlined by ExprCodeGenerator's ROW case into a GenericRowData build.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
