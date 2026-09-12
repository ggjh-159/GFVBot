# NOT_BETWEEN

Category: [Comparison](../index.md#comparison) | Aliases: —

## Role and scenarios

`x NOT BETWEEN lo AND hi` is the negation of BETWEEN: TRUE when x lies outside the closed range; NULL operands still yield UNKNOWN (outside-or-unknown is not simply the inverse). Used to exclude a band of values.

## Usage

Input: `x NOT BETWEEN lo AND hi` — same typing as BETWEEN; NULL input yields UNKNOWN.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.price NOT BETWEEN 10.00 AND 60.00 FROM bid;
```

Output: BOOLEAN; true for rows with `price` below 10.00 or above 60.00 (data-dependent).

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| price | price NOT BETWEEN 10.00 AND 60.00 |
|---|---|
| 55.67 | FALSE |
| 12.50 | FALSE |
| 99.99 | TRUE |
| 3.14 | TRUE |
| 61.20 | TRUE |
| 28.05 | FALSE |
| 77.77 | TRUE |
| 45.00 | FALSE |

## Pipeline

The route of `NOT_BETWEEN` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — keyword NOT BETWEEN..AND; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.NOT_BETWEEN` (FlinkSqlOperatorTable.java:1161).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:580, registered under the name "notBetween", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — Rewritten during Sql-to-Rex conversion into a SEARCH RexCall (SARG range); at codegen SearchOperatorGen expands it back into interval comparisons.
4. **Codegen** — Inlined by ExprCodeGenerator into plain Java operator code (ScalarOperatorGens); no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
