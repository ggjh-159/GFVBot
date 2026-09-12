# MOD

Category: [Arithmetic](../index.md#arithmetic) | Aliases: `%`

## Role and scenarios

Remainder of integer division; the sign follows the dividend. Bucketing rows (`MOD(id, n)` for sharding or sampling), cycling over periods, and parity checks.

## Usage

Input: `MOD(a, b)` or `a % b` — integer (or decimal) operands; division by zero raises an error.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, MOD(bid.auction, 7) FROM bid;
```

Output: BIGINT; remainder of `auction / 7`, i.e. 0-6 per row (data-dependent).

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| auction | MOD(auction, 7) |
|---|---|
| 3 | 3 |
| 19 | 5 |
| 8 | 1 |
| 1 | 1 |
| 14 | 0 |
| 7 | 0 |
| 11 | 4 |
| 20 | 6 |

## Pipeline

The route of `MOD` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form or infix %; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.MOD` (FlinkSqlOperatorTable.java:1186).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1483, registered under the name "mod", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — Inlined by ExprCodeGenerator into plain Java operator code (ScalarOperatorGens); no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
