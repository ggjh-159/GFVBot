# SIGN

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Returns the sign of x: -1 when x is negative, 0 when it is zero, and 1 when it is positive; the result type follows the input. It is used to derive direction flags from signed values.

## Usage

Signature: `SIGN(x)`

| Parameter | Type | Description |
|---|---|---|
| x | Numeric | Numeric expression whose sign is to be taken |

Return: -1, 0, or 1; the type follows the input.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, SIGN(bid.auction - 30) FROM bid;
```

Output: The sign of `auction - 30` for each row: -1, 0, or 1 (varies with the row data).

Example (first 8 of the 16 source rows, illustrative data; leading columns are input columns, the last column is the result for that row):

| auction | SIGN(auction - 30) | Notes |
|---|---|---|
| 3 | -1 | 3-30=-27, negative |
| 19 | -1 | 19-30=-11, negative |
| 8 | -1 | 8-30=-22, negative |
| 1 | -1 | 1-30=-29, negative |
| 14 | -1 | 14-30=-16, negative |
| 7 | -1 | 7-30=-23, negative |
| 11 | -1 | 11-30=-19, negative |
| 20 | -1 | 20-30=-10, negative |
| SIGN(0) | 0 | When the input is 0, the sign is 0 |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `SIGN` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `SIGN` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | static methods of `BuiltInMethods` (invoked via `MethodCallGen`) |

## Velox implementation

Velox already provides the builtin `sign` (`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`).
