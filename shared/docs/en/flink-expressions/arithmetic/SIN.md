# SIN

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Returns the sine of x; the operand is in radians rather than degrees. It is used for waveform features and periodic encoding.

## Usage

Signature: `SIN(x)`

| Parameter | Type | Description |
|---|---|---|
| x | DOUBLE | Angle in radians |

Return: DOUBLE.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, SIN(0) FROM bid;
```

Output: DOUBLE; `SIN(0)` is 0.0 on every row.

Example (input → output):

| Input | Output | Notes |
|---|---|---|
| SIN(0) | 0.0 | The sine is 0 at 0 radians |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `SIN` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `SIN` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | static methods of `BuiltInMethods` (invoked via `MethodCallGen`) |

## Velox implementation

Velox already provides the builtin `sin` (`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`).
