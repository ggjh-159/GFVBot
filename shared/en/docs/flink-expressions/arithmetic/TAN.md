# TAN

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Returns the tangent of x; the operand is in radians rather than degrees. It is used for slope and direction computations.

## Usage

Signature: `TAN(x)`

| Parameter | Type | Description |
|---|---|---|
| x | DOUBLE | Angle in radians |

Return: DOUBLE.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, TAN(0) FROM bid;
```

Output: DOUBLE; `TAN(0)` is 0.0 on every row.

Example (input → output):

| Input | Output | Notes |
|---|---|---|
| TAN(0) | 0.0 | The tangent is 0 at 0 radians |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `TAN` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `TAN` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | static methods of `BuiltInMethods` (invoked via `MethodCallGen`) |

## Velox implementation

Velox already provides the builtin `tan` (`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`).
