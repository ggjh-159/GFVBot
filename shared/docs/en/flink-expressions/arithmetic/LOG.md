# LOG

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Takes the logarithm of x to the explicitly given base; base must be positive and not equal to 1, and x must be positive; when either condition is not satisfied the result is NULL. It fits domains where neither e nor 10 is the natural base.

## Usage

Signature: `LOG(base, x)`

| Parameter | Type | Description |
|---|---|---|
| base | DOUBLE | Base of the logarithm; must be positive and not equal to 1 |
| x | DOUBLE | Logarithm argument; must be positive |

Return: DOUBLE; NULL for an illegal base or a non-positive argument.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, LOG(2, 8) FROM bid;
```

Output: DOUBLE; `LOG(2, 8)` is 3.0 on every row.

Example (input → output):

| Input | Output | Notes |
|---|---|---|
| LOG(2, 8) | 3.0 | 2 to the 3rd power is 8 |
| LOG(1, 8) | NULL | Base equals 1, illegal |
| LOG(2, -8) | NULL | Non-positive argument, illegal |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `LOG` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `LOG` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | static methods of `BuiltInMethods` (invoked via `MethodCallGen`) |

## Velox implementation

Velox already provides an implementation: the sparksql suite's `log` (`velox/functions/sparksql/registration/RegisterMath.cpp`).
