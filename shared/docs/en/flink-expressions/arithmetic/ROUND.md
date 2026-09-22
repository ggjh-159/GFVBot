# ROUND

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Rounds x to d decimal places (0 when d is omitted), with half-up handling for the common numeric types; it is used for monetary display and statistics at a fixed granularity.

## Usage

Signature: `ROUND(x)` or `ROUND(x, d)`

| Parameter | Type | Description |
|---|---|---|
| x | Numeric | Value to round |
| d | Non-negative integer literal | Number of decimal places to keep; 0 when omitted |

Return: The value rounded to d decimal places; the type follows the input.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, ROUND(bid.price, 1) FROM bid;
```

Output: The decimal value of each row kept to 1 decimal place, e.g. 55.67 becomes 55.7.

Example (first 8 of the 16 source rows, illustrative data; leading columns are input columns, the last column is the result for that row):

| price | ROUND(price, 1) | Notes |
|---|---|---|
| 55.67 | 55.7 | The 2nd decimal digit 7 carries up |
| 12.50 | 12.5 | The 2nd decimal digit 0 is dropped |
| 99.99 | 100.0 | Chained carries increase the integer part by one |
| 3.14 | 3.1 | The 2nd decimal digit 4 is dropped |
| 61.20 | 61.2 | The 2nd decimal digit 0 is dropped |
| 28.05 | 28.1 | Half-up: the 2nd decimal digit 5 carries up |
| 77.77 | 77.8 | The 2nd decimal digit 7 carries up |
| 45.00 | 45.0 | No lower decimal digits remain; the value is unchanged |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `ROUND` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `ROUND` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | static methods of `BuiltInMethods` (invoked via `MethodCallGen`) |

## Velox implementation

Velox already provides the builtin `round` (`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`).
