# ASIN

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Returns the principal value of the arc sine of x, expressed in radians, with range [-π/2, π/2]. The input must lie within [-1, 1]; outside that domain (|x| > 1) the result is NULL. It is used to invert sine-type features.

## Usage

Signature: `ASIN(x)`

| Parameter | Type | Description |
|---|---|---|
| x | DOUBLE | Sine value; the valid domain is [-1, 1] |

Return: DOUBLE, radians within [-π/2, π/2]; NULL when |x| > 1.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, ASIN(0.5) FROM bid;
```

Output: DOUBLE; `ASIN(0.5)` is 0.5235987755982989 on every row.

Example (input → output):

| Input | Output | Notes |
|---|---|---|
| ASIN(0.5) | 0.5235987755982989 | The sine value 0.5 corresponds to the radian π/6 |
| ASIN(2) | NULL | Input outside [-1, 1]; the result is NULL |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `ASIN` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `ASIN` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | static methods of `BuiltInMethods` (invoked via `MethodCallGen`) |

## Velox implementation

Velox already provides the builtin `asin` (`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`).
