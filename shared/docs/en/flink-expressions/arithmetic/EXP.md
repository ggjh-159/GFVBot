# EXP

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

e raised to the power x. Exponential growth and decay models, softmax-style weights.

## Usage

Input: `EXP(x)` — DOUBLE.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, EXP(2) FROM bid;
```

Output: DOUBLE; `EXP(2)` = 7.38905609893065 on every row.

Example (input -> output):

| Input | Output |
|---|
| EXP(2) | 7.38905609893065 |

## Pipeline

The route of `EXP` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.EXP` (FlinkSqlOperatorTable.java:1190).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1393, registered under the name "exp", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — MethodCallGen on a FunctionGenerator-registered BuiltInMethods static helper; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
