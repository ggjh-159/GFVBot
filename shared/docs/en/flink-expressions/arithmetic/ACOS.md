# ACOS

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Returns the principal value of the arc cosine of x, expressed in radians, with range [0, π]. The input must lie within [-1, 1]; outside that domain (|x| > 1) the result is NULL. It is used to convert similarity or ratio inputs into angles.

## Usage

Signature: `ACOS(x)`

| Parameter | Type | Description |
|---|---|---|
| x | DOUBLE | Cosine value; the valid domain is [-1, 1] |

Return: DOUBLE, radians within [0, π]; NULL when |x| > 1.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, ACOS(0.5) FROM bid;
```

Output: DOUBLE; `ACOS(0.5)` is 1.0471975511965979 on every row.

Example (input → output):

| Input | Output | Notes |
|---|---|---|
| ACOS(0.5) | 1.0471975511965979 | The cosine value 0.5 corresponds to the radian π/3 |
| ACOS(2) | NULL | Input outside [-1, 1]; the result is NULL |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `ACOS` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `ACOS` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | static methods of `BuiltInMethods` (invoked via `MethodCallGen`) |

## Velox implementation

Velox already provides the builtin `acos` (`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`).
