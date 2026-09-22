# DEGREES

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Converts the radian value x into degrees, i.e. x multiplied by 180/π. It is used to convert the radian output of trigonometric functions into degree units.

## Usage

Signature: `DEGREES(x)`

| Parameter | Type | Description |
|---|---|---|
| x | DOUBLE | Radian value |

Return: DOUBLE; the corresponding value in degrees.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, DEGREES(1) FROM bid;
```

Output: DOUBLE; `DEGREES(1)` is 57.29577951308232 on every row.

Example (input → output):

| Input | Output | Notes |
|---|---|---|
| DEGREES(1) | 57.29577951308232 | 1 radian is approximately 57.2958 degrees |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `DEGREES` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `DEGREES` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | static methods of `BuiltInMethods` (invoked via `MethodCallGen`) |

## Velox implementation

Velox already provides the builtin `degrees` (`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`).
