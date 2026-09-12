# E

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Euler's number e as a DOUBLE. Zero-argument but written with parentheses: `E()`.

## Usage

Input: `E()` — no arguments; DOUBLE.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, E() FROM bid;
```

Output: DOUBLE; 2.718281828459045 on every row.

Example (input -> output):

| Input | Output |
|---|
| — | 2.718281828459045 |

## Pipeline

The route of `E` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — zero-arg function E(); the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.E` (FlinkSqlOperatorTable.java:210).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1653, registered under the name "e", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — ConstantCallGen inlines the Math.E constant into the generated code.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
