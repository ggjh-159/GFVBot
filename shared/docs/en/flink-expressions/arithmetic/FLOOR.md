# FLOOR

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Largest integer not greater than x. With the temporal form `FLOOR(ts TO unit)` it truncates a timestamp down to the given unit boundary (HOUR, DAY, MONTH, ...). Snap-to-bucket operations.

## Usage

Input: `FLOOR(x)` — numeric; `FLOOR(ts TO unit)` — temporal.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, FLOOR(bid.price) FROM bid;
```

Output: Decimal with the fraction removed per row, e.g. 55.67 becomes 55.

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| price | FLOOR(price) |
|---|---|
| 55.67 | 55 |
| 12.50 | 12 |
| 99.99 | 99 |
| 3.14 | 3 |
| 61.20 | 61 |
| 28.05 | 28 |
| 77.77 | 77 |
| 45.00 | 45 |

## Pipeline

The route of `FLOOR` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.FLOOR` (FlinkSqlOperatorTable.java:1192).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1401, registered under the name "floor", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — FloorCeilCallGen — numeric via BuiltInMethods.FLOOR/CEIL, temporal truncation via the UNIX_DATE/UNIX_TIMESTAMP floor/ceil helpers.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
