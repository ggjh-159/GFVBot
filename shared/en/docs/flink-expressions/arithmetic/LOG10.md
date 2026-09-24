# LOG10

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Returns the common logarithm (base 10) of x; when the input is non-positive (x <= 0) the result is NULL. It is used for decibel-style and order-of-magnitude measures.

## Usage

Signature: `LOG10(x)`

| Parameter | Type | Description |
|---|---|---|
| x | DOUBLE | Logarithm argument; must be positive |

Return: DOUBLE; NULL when x <= 0.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, LOG10(100) FROM bid;
```

Output: DOUBLE; `LOG10(100)` is 2.0 on every row.

Example (input → output):

| Input | Output | Notes |
|---|---|---|
| LOG10(100) | 2.0 | 10 to the 2nd power is 100 |
| LOG10(-1) | NULL | Non-positive input returns NULL |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `LOG10` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `LOG10` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | static methods of `BuiltInMethods` (invoked via `MethodCallGen`) |

## Velox implementation

Velox already provides the builtin `log10` (`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`).
