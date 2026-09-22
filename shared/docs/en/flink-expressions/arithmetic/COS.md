# COS

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Returns the cosine of x; the operand is in radians rather than degrees. It is used for periodic encoding and phase-related computations.

## Usage

Signature: `COS(x)`

| Parameter | Type | Description |
|---|---|---|
| x | DOUBLE | Angle in radians |

Return: DOUBLE.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, COS(0) FROM bid;
```

Output: DOUBLE; `COS(0)` is 1.0 on every row.

Example (input → output):

| Input | Output | Notes |
|---|---|---|
| COS(0) | 1.0 | The cosine reaches its maximum 1 at 0 radians |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `COS` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `COS` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | static methods of `BuiltInMethods` (invoked via `MethodCallGen`) |

## Velox implementation

Velox already provides the builtin `cos` (`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`).
