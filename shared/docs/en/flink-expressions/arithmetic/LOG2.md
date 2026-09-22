# LOG2

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Returns the base-2 logarithm of x; when the input is non-positive (x <= 0) the result is NULL. It is used for measuring required bit widths and tree-depth-style computations.

## Usage

Signature: `LOG2(x)`

| Parameter | Type | Description |
|---|---|---|
| x | DOUBLE | Logarithm argument; must be positive |

Return: DOUBLE; NULL when x <= 0.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, LOG2(8) FROM bid;
```

Output: DOUBLE; `LOG2(8)` is 3.0 on every row.

Example (input → output):

| Input | Output | Notes |
|---|---|---|
| LOG2(8) | 3.0 | 2 to the 3rd power is 8 |
| LOG2(0) | NULL | Non-positive input returns NULL |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `LOG2` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `LOG2` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | static methods of `BuiltInMethods` (invoked via `MethodCallGen`) |

## Velox implementation

Velox already provides the builtin `log2` (`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`).
