# COT

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Cotangent, i.e. cosine over sine. Occasional in geometric derivations; undefined where sine is zero (yields NULL).

## Usage

Input: `COT(x)` — DOUBLE, x in radians.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, COT(1) FROM bid;
```

Output: DOUBLE; `COT(1)` = 0.6420926159343306 on every row.

Example (input -> output):

| Input | Output |
|---|
| COT(1) | 0.6420926159343306 |

## Pipeline

The route of `COT` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.COT` (FlinkSqlOperatorTable.java:1200).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1557, registered under the name "cot", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — MethodCallGen on a FunctionGenerator-registered BuiltInMethods static helper; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
