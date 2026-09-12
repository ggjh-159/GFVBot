# PI

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

The constant pi as a DOUBLE. Zero-argument but written with parentheses: `PI()`.

## Usage

Input: `PI()` — no arguments; DOUBLE.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, PI() FROM bid;
```

Output: DOUBLE; 3.141592653589793 on every row.

Example (input -> output):

| Input | Output |
|---|
| — | 3.141592653589793 |

## Pipeline

The route of `PI` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — zero-arg function PI(); the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.PI_FUNCTION` (FlinkSqlOperatorTable.java:218).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1645, registered under the name "pi", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — ConstantCallGen inlines the Math.PI constant into the generated code.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
