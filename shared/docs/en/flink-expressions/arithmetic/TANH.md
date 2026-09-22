# TANH

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Returns the hyperbolic tangent of x; the output always falls within (-1, 1). It is used to squeeze features into a bounded interval and is a common pre-normalization technique.

## Usage

Signature: `TANH(x)`

| Parameter | Type | Description |
|---|---|---|
| x | DOUBLE | Any real number |

Return: DOUBLE, falling within (-1, 1).

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, TANH(1) FROM bid;
```

Output: DOUBLE; `TANH(1)` is 0.7615941559557649 on every row.

Example (input → output):

| Input | Output | Notes |
|---|---|---|
| TANH(1) | 0.7615941559557649 | The output lies strictly between -1 and 1 |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `TANH` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `TANH` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | static methods of `BuiltInMethods` (invoked via `MethodCallGen`) |

## Velox implementation

Velox already provides the builtin `tanh` (`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`).
