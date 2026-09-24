# POWER

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Returns base raised to the power exp, with a DOUBLE result; it is used for polynomial features and compound-interest-style formulas.

## Usage

Signature: `POWER(base, exp)`

| Parameter | Type | Description |
|---|---|---|
| base | Numeric | Base |
| exp | Numeric | Exponent |

Return: DOUBLE.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, POWER(2, 10) FROM bid;
```

Output: DOUBLE; `POWER(2, 10)` is 1024.0 on every row.

Example (input → output):

| Input | Output | Notes |
|---|---|---|
| POWER(2, 10) | 1024.0 | 2 to the 10th power |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `POWER` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `POWER` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | static methods of `BuiltInMethods` (invoked via `MethodCallGen`) |

## Velox implementation

Velox already provides the builtin `power` (`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`).
