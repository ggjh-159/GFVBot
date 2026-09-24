# EXP

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Returns e raised to the power x. It is used for exponential growth/decay models and softmax-style weight computation.

## Usage

Signature: `EXP(x)`

| Parameter | Type | Description |
|---|---|---|
| x | DOUBLE | Exponent |

Return: DOUBLE.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, EXP(2) FROM bid;
```

Output: DOUBLE; `EXP(2)` is 7.38905609893065 on every row.

Example (input → output):

| Input | Output | Notes |
|---|---|---|
| EXP(2) | 7.38905609893065 | e to the 2nd power |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `EXP` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `EXP` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | static methods of `BuiltInMethods` (invoked via `MethodCallGen`) |

## Velox implementation

Velox already provides the builtin `exp` (`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`).
