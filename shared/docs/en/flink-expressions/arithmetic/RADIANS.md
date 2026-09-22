# RADIANS

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Converts the degree value x into radians, i.e. x multiplied by π/180. It is used to convert degree-based inputs so they can be consumed by the trigonometric functions, which work in radians.

## Usage

Signature: `RADIANS(x)`

| Parameter | Type | Description |
|---|---|---|
| x | DOUBLE | Degree value |

Return: DOUBLE; the corresponding value in radians.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, RADIANS(90) FROM bid;
```

Output: DOUBLE; `RADIANS(90)` is 1.5707963267948966 on every row.

Example (input → output):

| Input | Output | Notes |
|---|---|---|
| RADIANS(90) | 1.5707963267948966 | 90 degrees equals π/2 radians |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `RADIANS` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `RADIANS` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | static methods of `BuiltInMethods` (invoked via `MethodCallGen`) |

## Velox implementation

Velox already provides the builtin `radians` (`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`).
