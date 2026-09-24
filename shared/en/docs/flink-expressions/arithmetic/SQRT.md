# SQRT

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Returns the square root of x; negative input (x < 0) yields NULL. It is used for Euclidean distance computation and for recovering the standard deviation from the variance.

## Usage

Signature: `SQRT(x)`

| Parameter | Type | Description |
|---|---|---|
| x | DOUBLE | Radicand; a negative value yields NULL |

Return: DOUBLE; NULL when x < 0.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, SQRT(16) FROM bid;
```

Output: DOUBLE; `SQRT(16)` is 4.0 on every row.

Example (input → output):

| Input | Output | Notes |
|---|---|---|
| SQRT(16) | 4.0 | The square of 4 is 16 |
| SQRT(-1) | NULL | Negative input returns NULL |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `SQRT` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `SQRT` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | static methods of `BuiltInMethods` (invoked via `MethodCallGen`) |

## Velox implementation

Velox already provides the builtin `sqrt` (`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`).
