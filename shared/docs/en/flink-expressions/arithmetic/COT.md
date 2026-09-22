# COT

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Returns the cotangent of x, i.e. the ratio of cosine to sine, with the operand in radians; it is undefined (yielding NULL) where the sine is zero. It occasionally appears in geometric derivations.

## Usage

Signature: `COT(x)`

| Parameter | Type | Description |
|---|---|---|
| x | DOUBLE | Angle in radians; undefined where the sine is zero |

Return: DOUBLE.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, COT(1) FROM bid;
```

Output: DOUBLE; `COT(1)` is 0.6420926159343306 on every row.

Example (input → output):

| Input | Output | Notes |
|---|---|---|
| COT(1) | 0.6420926159343306 | That is, cos(1)/sin(1) |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `COT` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `COT` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | static methods of `BuiltInMethods` (invoked via `MethodCallGen`) |

## Velox implementation

Velox already provides an implementation: the sparksql suite's `cot` (`velox/functions/sparksql/registration/RegisterMath.cpp`).
