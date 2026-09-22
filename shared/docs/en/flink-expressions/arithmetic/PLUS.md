# PLUS

Category: [Arithmetic](../index.md#arithmetic) | Aliases: `+`

## Role and scenarios

Addition (infix `+`): supports numeric plus numeric and temporal types plus intervals; in the numeric case the result type is widened according to the Flink type system. When either operand is NULL, the result is NULL. It is widely used in derived metrics — the q1-pattern column `0.908 * price + 10` is a PLUS on top of a multiplication.

## Usage

Signature: `a + b` (infix addition)

| Parameter | Type | Description |
|---|---|---|
| Left operand | Numeric or temporal type | Addend; temporal types plus intervals are also supported |
| Right operand | Numeric or interval | Addend |

Return: The sum; in the numeric case the result type is widened according to the Flink type system. NULL when either operand is NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.auction + bid.bidder FROM bid;
```

Output: BIGINT; `auction + bidder` for each row (varies with the row data).

Example (first 8 of the 16 source rows, illustrative data; leading columns are input columns, the last column is the result for that row):

| auction | bidder | auction + bidder | Notes |
|---|---|---|---|
| 3 | 15 | 18 | 3+15=18 |
| 19 | 7 | 26 | 19+7=26 |
| 8 | 8 | 16 | 8+8=16 |
| 1 | 42 | 43 | 1+42=43 |
| 14 | 23 | 37 | 14+23=37 |
| 7 | 2 | 9 | 7+2=9 |
| 11 | 11 | 22 | 11+11=22 |
| 20 | 36 | 56 | 20+36=56 |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `PLUS` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `PLUS` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | inlined by `ScalarOperatorGens` |

## Velox implementation

Velox already provides the builtin `plus` (`velox/functions/prestosql/registration/MathematicalOperatorsRegistration.cpp`).
