# BETWEEN

Category: [Comparison](../index.md#comparison) | Aliases: —

## Role and scenarios

`x BETWEEN lo AND hi` is shorthand for `x >= lo AND x <= hi` — inclusive on both ends; NULL operands yield UNKNOWN. The readable form of range filters such as price bands and time windows.

## Usage

Input: `x BETWEEN lo AND hi` — x, lo, hi of a common comparable type; NULL input yields UNKNOWN.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.price BETWEEN 10.00 AND 60.00 FROM bid;
```

Output: BOOLEAN; true for rows with `price` from 10.00 to 60.00 inclusive (data-dependent).

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| price | price BETWEEN 10.00 AND 60.00 |
|---|---|
| 55.67 | TRUE |
| 12.50 | TRUE |
| 99.99 | FALSE |
| 3.14 | FALSE |
| 61.20 | FALSE |
| 28.05 | TRUE |
| 77.77 | FALSE |
| 45.00 | TRUE |

## Pipeline

The route of `BETWEEN` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — keyword BETWEEN..AND; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.BETWEEN` (FlinkSqlOperatorTable.java:1159).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:564, registered under the name "between", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — Rewritten during Sql-to-Rex conversion into a SEARCH RexCall (SARG range); at codegen SearchOperatorGen expands it back into interval comparisons.
4. **Codegen** — Inlined by ExprCodeGenerator into plain Java operator code (ScalarOperatorGens); no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
