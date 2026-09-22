# SINH

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Returns the hyperbolic sine of x; it acts as a bridge between exponentials in some growth models.

## Usage

Signature: `SINH(x)`

| Parameter | Type | Description |
|---|---|---|
| x | DOUBLE | Any real number |

Return: DOUBLE.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, SINH(1) FROM bid;
```

Output: DOUBLE; `SINH(1)` is 1.1752011936438014 on every row.

Example (input → output):

| Input | Output | Notes |
|---|---|---|
| SINH(1) | 1.1752011936438014 | The value of (e-1/e)/2 at x=1 |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `SINH` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `SINH` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | static methods of `BuiltInMethods` (invoked via `MethodCallGen`) |

## Velox implementation

Velox already provides an implementation: the sparksql suite's `sinh` (`velox/functions/sparksql/registration/RegisterMath.cpp`).
