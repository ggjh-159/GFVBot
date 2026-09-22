# COSH

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Returns the hyperbolic cosine of x; the output is always not less than 1. It is the even-function component of the exponential family.

## Usage

Signature: `COSH(x)`

| Parameter | Type | Description |
|---|---|---|
| x | DOUBLE | Any real number |

Return: DOUBLE; never less than 1.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, COSH(1) FROM bid;
```

Output: DOUBLE; `COSH(1)` is 1.543080634815244 on every row.

Example (input → output):

| Input | Output | Notes |
|---|---|---|
| COSH(1) | 1.543080634815244 | The value of (e+1/e)/2 at x=1 |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `COSH` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `COSH` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | static methods of `BuiltInMethods` (invoked via `MethodCallGen`) |

## Velox implementation

Velox already provides the builtin `cosh` (`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`).
