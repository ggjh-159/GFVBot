# CEIL

Category: [Arithmetic](../index.md#arithmetic) | Aliases: `CEILING`

## Role and scenarios

Smallest integer not less than x; CEILING is the alternate spelling. `CEIL(ts TO unit)` rounds a timestamp up to the unit boundary. Capacity rounding — pages, batches, billing blocks.

## Usage

Input: `CEIL(x)` or `CEILING(x)` — numeric; `CEIL(ts TO unit)` — temporal.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, CEIL(bid.price) FROM bid;
```

Output: Decimal rounded up to the next integer per row, e.g. 55.01 becomes 56.

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| price | CEIL(price) |
|---|---|
| 55.67 | 56 |
| 12.50 | 13 |
| 99.99 | 100 |
| 3.14 | 4 |
| 61.20 | 62 |
| 28.05 | 29 |
| 77.77 | 78 |
| 45.00 | 45 |

## Pipeline

The route of `CEIL` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form (CEILING is an alias); the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.CEIL` (FlinkSqlOperatorTable.java:1193).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1418, registered under the name "ceil", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — FloorCeilCallGen — numeric via BuiltInMethods.FLOOR/CEIL, temporal truncation via the UNIX_DATE/UNIX_TIMESTAMP floor/ceil helpers.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
