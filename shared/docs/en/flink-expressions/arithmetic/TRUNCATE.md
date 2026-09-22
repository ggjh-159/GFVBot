# TRUNCATE

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Truncates x at d decimal places (0 when d is omitted); the digits beyond d are simply dropped, with no rounding. Where ROUND's half-up would overestimate, truncation keeps a conservative result.

## Usage

Signature: `TRUNCATE(x)` or `TRUNCATE(x, d)`

| Parameter | Type | Description |
|---|---|---|
| x | Numeric | Value to truncate |
| d | Non-negative integer literal | Number of decimal places to keep; 0 when omitted |

Return: The value truncated at d decimal places; the type follows the input.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, TRUNCATE(bid.price, 1) FROM bid;
```

Output: The decimal value of each row truncated at 1 decimal place, e.g. 55.67 becomes 55.6.

Example (first 8 of the 16 source rows, illustrative data; leading columns are input columns, the last column is the result for that row):

| price | TRUNCATE(price, 1) | Notes |
|---|---|---|
| 55.67 | 55.6 | The 2nd decimal digit is simply dropped |
| 12.50 | 12.5 | Drops a 0; the value is unchanged |
| 99.99 | 99.9 | The 2nd decimal digit is simply dropped |
| 3.14 | 3.1 | The 2nd decimal digit 4 is simply dropped |
| 61.20 | 61.2 | Drops a 0; the value is unchanged |
| 28.05 | 28.0 | The 2nd decimal digit 5 does not carry up; it is simply dropped |
| 77.77 | 77.7 | The 2nd decimal digit is simply dropped |
| 45.00 | 45.0 | No lower decimal digits remain; the value is unchanged |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `TRUNCATE` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `TRUNCATE` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | static methods of `BuiltInMethods` (invoked via `MethodCallGen`) |

## Velox implementation

Velox already provides the builtin `truncate` (`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`).
