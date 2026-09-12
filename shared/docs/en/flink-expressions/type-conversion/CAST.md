# CAST

Category: [Type Conversion](../index.md#type-conversion) | Aliases: —

## Role and scenarios

Explicit type conversion across the wide matrix — numeric widenings and narrowings, string to and from numeric, string to and from temporal, and composite re-labels. An impossible conversion raises a runtime error.

## Usage

Input: `CAST(x AS t)` — t a concrete SQL type.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, CAST(bid.auction AS VARCHAR) FROM bid;
```

Output: VARCHAR; the decimal digits of `auction` per row (data-dependent).

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| auction | CAST(auction AS VARCHAR) |
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

The route of `CAST` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — CAST(x AS t); the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.CAST` (FlinkSqlOperatorTable.java:1194).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:2390, registered under the name "cast", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — ExprCodeGenerator's CAST case generates type-pair-specific conversion code (numeric/string/temporal matrix).
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
