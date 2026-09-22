# MINUS

Category: [Arithmetic](../index.md#arithmetic) | Aliases: `-`

## Role and scenarios

Subtraction (infix `-`): supports numeric minus numeric, temporal minus interval, and interval minus interval. When either operand is NULL, the result is NULL. It is used for differences and centering values.

## Usage

Signature: `a - b` (infix subtraction)

| Parameter | Type | Description |
|---|---|---|
| Left operand | Numeric, temporal, or interval | Minuend; supports numeric, temporal minus interval, and interval minus interval |
| Right operand | Numeric or interval | Subtrahend |

Return: The difference; numeric, temporal, or interval, with the type derived from the operand combination. NULL when either operand is NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.auction - bid.bidder FROM bid;
```

Output: BIGINT; `auction - bidder` for each row (varies with the row data).

Example (first 8 of the 16 source rows, illustrative data; leading columns are input columns, the last column is the result for that row):

| auction | bidder | auction - bidder | Notes |
|---|---|---|---|
| 3 | 15 | -12 | The minuend is smaller than the subtrahend; the difference is negative |
| 19 | 7 | 12 | The difference is positive |
| 8 | 8 | 0 | The two values are equal; the difference is 0 |
| 1 | 42 | -41 | The minuend is smaller than the subtrahend; the difference is negative |
| 14 | 23 | -9 | The minuend is smaller than the subtrahend; the difference is negative |
| 7 | 2 | 5 | The difference is positive |
| 11 | 11 | 0 | The two values are equal; the difference is 0 |
| 20 | 36 | -16 | The minuend is smaller than the subtrahend; the difference is negative |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `MINUS` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `MINUS` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | inlined by `ScalarOperatorGens` |

## Velox implementation

Velox already provides the builtin `minus` (`velox/functions/prestosql/registration/MathematicalOperatorsRegistration.cpp`).
