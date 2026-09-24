# NOT_BETWEEN

Category: [Comparison](../index.md#comparison) | Aliases: —

## Role and scenarios

`x NOT BETWEEN lo AND hi` is the negation of BETWEEN: TRUE when x lies outside the closed interval; any NULL operand still yields UNKNOWN, so it is not a plain inversion of BETWEEN. Used to exclude a range of values.

## Usage

Signature: `x NOT BETWEEN lo AND hi` — each part has the same meaning as in BETWEEN: x is the expression under test, and lo and hi are the lower and upper bounds of the same comparable type.

Return: BOOLEAN; TRUE when x lies outside the closed interval `[lo, hi]`; UNKNOWN when any operand is NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.price NOT BETWEEN 10.00 AND 60.00 FROM bid;
```

Output: BOOLEAN; true when `price` is below 10.00 or above 60.00 (varies with row data).

Example (first 8 rows of the 16-row source, illustrative data, with a final NULL-boundary row appended; leading columns are inputs, the last two are each row's result and notes):

| price | price NOT BETWEEN 10.00 AND 60.00 | Notes |
|---|---|---|
| 55.67 | FALSE | Inside the closed interval |
| 12.50 | FALSE | Inside the closed interval |
| 99.99 | TRUE | Above the upper bound |
| 3.14 | TRUE | Below the lower bound |
| 61.20 | TRUE | Above the upper bound |
| 28.05 | FALSE | Inside the closed interval |
| 77.77 | TRUE | Above the upper bound |
| 45.00 | FALSE | Inside the closed interval |
| NULL | UNKNOWN | NULL input still yields UNKNOWN, not TRUE |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | The `NOT_BETWEEN` entry in `FlinkSqlOperatorTable`; rewritten to a SEARCH RexCall (SARG range) during Sql-to-Rex conversion |
| Definition and type inference | The `NOT_BETWEEN` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | After the rewrite to SEARCH, expanded into interval comparisons by `SearchOperatorGen` |

## Velox implementation

Velox already provides the builtin `between` (`velox/functions/prestosql/registration/ComparisonFunctionsRegistration.cpp`) (the negation must be done at the expression level).
