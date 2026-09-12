# TAN

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Tangent of an angle in radians. Slope and direction computations.

## Usage

Input: `TAN(x)` — DOUBLE, x in radians.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, TAN(0) FROM bid;
```

Output: DOUBLE; `TAN(0)` = 0.0 on every row.

Example (input -> output):

| Input | Output |
|---|
| TAN(0) | 0.0 |

## Pipeline

The route of `TAN` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.TAN` (FlinkSqlOperatorTable.java:1199).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1541, registered under the name "tan", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — MethodCallGen on a FunctionGenerator-registered BuiltInMethods static helper; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
