# ATAN

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Returns the principal value of the arc tangent of x, expressed in radians, with range (-π/2, π/2). It is used to convert a ratio back into an angle.

## Usage

Signature: `ATAN(x)`

| Parameter | Type | Description |
|---|---|---|
| x | DOUBLE | Tangent value; any value is accepted |

Return: DOUBLE, radians within (-π/2, π/2).

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, ATAN(1) FROM bid;
```

Output: DOUBLE; `ATAN(1)` is 0.7853981633974483 on every row.

Example (input → output):

| Input | Output | Notes |
|---|---|---|
| ATAN(1) | 0.7853981633974483 | The tangent value 1 corresponds to the radian π/4 |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `ATAN` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `ATAN` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | static methods of `BuiltInMethods` (invoked via `MethodCallGen`) |

## Velox implementation

Velox already provides the builtin `atan` (`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`).
