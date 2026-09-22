# BETWEEN

Category: [Comparison](../index.md#comparison) | Aliases: —

## Role and scenarios

`x BETWEEN lo AND hi` is equivalent to `x >= lo AND x <= hi`, with both ends forming a closed interval; UNKNOWN when any operand is NULL. An intuitive spelling for range filters such as price bands and time windows.

## Usage

Signature: `x BETWEEN lo AND hi` — x is the expression under test; lo and hi are the lower and upper bounds, of the same comparable type as x.

Return: BOOLEAN; TRUE when x falls inside the closed interval `[lo, hi]`; UNKNOWN when any operand is NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.price BETWEEN 10.00 AND 60.00 FROM bid;
```

Output: BOOLEAN; true when `price` falls within 10.00 to 60.00 inclusive (varies with row data).

Example (first 8 rows of the 16-row source, illustrative data, with a final NULL-boundary row appended; leading columns are inputs, the last two are each row's result and notes):

| price | price BETWEEN 10.00 AND 60.00 | Notes |
|---|---|---|
| 55.67 | TRUE | Inside the closed interval |
| 12.50 | TRUE | Inside the closed interval |
| 99.99 | FALSE | Above the upper bound |
| 3.14 | FALSE | Below the lower bound |
| 61.20 | FALSE | Above the upper bound |
| 28.05 | TRUE | Inside the closed interval |
| 77.77 | FALSE | Above the upper bound |
| 45.00 | TRUE | Inside the closed interval |
| NULL | UNKNOWN | Any NULL operand yields UNKNOWN |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | The `BETWEEN` entry in `FlinkSqlOperatorTable`; rewritten to a SEARCH RexCall (SARG range) during Sql-to-Rex conversion |
| Definition and type inference | The `BETWEEN` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | After the rewrite to SEARCH, expanded into interval comparisons by `SearchOperatorGen` |

## Velox implementation

Velox already provides the builtin `between` (`velox/functions/prestosql/registration/ComparisonFunctionsRegistration.cpp`).
