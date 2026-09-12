# ATAN2

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Two-argument arc tangent: the angle of the point (y, x), using both signs to pick the quadrant — unlike ATAN it distinguishes opposite corners. Bearing from coordinate deltas.

## Usage

Input: `ATAN2(y, x)` — DOUBLE.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, ATAN2(1, 1) FROM bid;
```

Output: DOUBLE; `ATAN2(1, 1)` = 0.7853981633974483 on every row.

Example (input -> output):

| Input | Output |
|---|
| ATAN2(1, 1) | 0.7853981633974483 |

## Pipeline

The route of `ATAN2` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.ATAN2` (FlinkSqlOperatorTable.java:1204).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1589, registered under the name "atan2", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — MethodCallGen on a FunctionGenerator-registered BuiltInMethods static helper; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
