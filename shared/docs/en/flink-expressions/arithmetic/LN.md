# LN

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Returns the natural logarithm (base e) of x; when the input is non-positive (x <= 0) the result is NULL. It is commonly used to apply logarithmic scaling to skewed distributions before aggregation.

## Usage

Signature: `LN(x)`

| Parameter | Type | Description |
|---|---|---|
| x | DOUBLE | Logarithm argument; must be positive |

Return: DOUBLE; NULL when x <= 0.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, LN(EXP(2)) FROM bid;
```

Output: DOUBLE; `LN(EXP(2))` is 2.0 on every row.

Example (input → output):

| Input | Output | Notes |
|---|---|---|
| LN(EXP(2)) | 2.0 | LN and EXP are inverse operations of each other |
| LN(0) | NULL | Non-positive input returns NULL |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `LN` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `LN` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | static methods of `BuiltInMethods` (invoked via `MethodCallGen`) |

## Velox implementation

Velox already provides the builtin `ln` (`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`).
