# ATAN2

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Two-argument arc tangent: returns the argument of the point (y, x), expressed in radians, with range [-π, π]. Unlike ATAN, ATAN2 selects the quadrant from the signs of the two operands and can distinguish diagonally opposite angles. It is used to compute bearings from coordinate differences.

## Usage

Signature: `ATAN2(y, x)`

| Parameter | Type | Description |
|---|---|---|
| y | DOUBLE | Ordinate of the point |
| x | DOUBLE | Abscissa of the point |

Return: DOUBLE, radians within [-π, π].

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, ATAN2(1, 1) FROM bid;
```

Output: DOUBLE; `ATAN2(1, 1)` is 0.7853981633974483 on every row.

Example (input → output):

| Input | Output | Notes |
|---|---|---|
| ATAN2(1, 1) | 0.7853981633974483 | The point (1, 1) lies in the first quadrant; its argument is π/4 |
| ATAN2(1, -1) | 2.356194490192345 | x is negative and y is positive, so the argument falls in the second quadrant (3π/4) |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `ATAN2` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `ATAN2` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | static methods of `BuiltInMethods` (invoked via `MethodCallGen`) |

## Velox implementation

Velox already provides the builtin `atan2` (`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`).
