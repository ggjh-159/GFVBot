# ABS

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Returns the absolute value of the numeric x; the result type is the same as the input. It is used to measure deviation magnitude and to normalize signed differences. When the input is NULL, the result is NULL.

## Usage

Signature: `ABS(x)`

| Parameter | Type | Description |
|---|---|---|
| x | Numeric | Numeric expression whose absolute value is to be taken |

Return: Same type as the input; NULL when the input is NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, ABS(bid.auction - 30) FROM bid;
```

Output: BIGINT; `ABS(auction - 30)` for each row (varies with the row data).

Example (first 8 of the 16 source rows, illustrative data; leading columns are input columns, the last column is the result for that row):

| auction | ABS(auction - 30) | Notes |
|---|---|---|
| 3 | 27 | 3-30=-27; the absolute value is 27 |
| 19 | 11 | 19-30=-11; the absolute value is 11 |
| 8 | 22 | 8-30=-22; the absolute value is 22 |
| 1 | 29 | 1-30=-29; the absolute value is 29 |
| 14 | 16 | 14-30=-16; the absolute value is 16 |
| 7 | 23 | 7-30=-23; the absolute value is 23 |
| 11 | 19 | 11-30=-19; the absolute value is 19 |
| 20 | 10 | 20-30=-10; the absolute value is 10 |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `ABS` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `ABS` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | static methods of `BuiltInMethods` (invoked via `MethodCallGen`) |

## Velox implementation

Velox already provides the builtin `abs` (`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`).
