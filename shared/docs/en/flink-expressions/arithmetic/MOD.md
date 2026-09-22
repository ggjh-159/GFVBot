# MOD

Category: [Arithmetic](../index.md#arithmetic) | Aliases: `%`

## Role and scenarios

Returns the remainder of division, supporting both the function form `MOD(a, b)` and the infix `a % b`; the sign of the remainder follows the dividend, and a zero divisor raises an error. It is commonly used for bucketing (e.g. `MOD(id, n)` for sharding or sampling), periodic cycling, and parity checks.

## Usage

Signature: `MOD(a, b)` or `a % b`

| Parameter | Type | Description |
|---|---|---|
| a | Integer or DECIMAL | Dividend |
| b | Integer or DECIMAL | Divisor; a value of 0 raises an error |

Return: The remainder, with its sign following the dividend; the type follows the operands.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, MOD(bid.auction, 7) FROM bid;
```

Output: BIGINT; the remainder of `auction / 7`, 0-6 per row (varies with the row data).

Example (first 8 of the 16 source rows, illustrative data; leading columns are input columns, the last column is the result for that row):

| auction | MOD(auction, 7) | Notes |
|---|---|---|
| 3 | 3 | 3=0×7+3 |
| 19 | 5 | 19=2×7+5 |
| 8 | 1 | 8=1×7+1 |
| 1 | 1 | 1=0×7+1 |
| 14 | 0 | Evenly divisible; the remainder is 0 |
| 7 | 0 | Evenly divisible; the remainder is 0 |
| 11 | 4 | 11=1×7+4 |
| 20 | 6 | 20=2×7+6 |
| MOD(-19, 7) | -5 | The sign of the remainder follows the dividend |
| MOD(7, 0) | Error | The divisor is 0 |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `MOD` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `MOD` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | inlined by `ScalarOperatorGens` |

## Velox implementation

Velox already provides the builtin `mod` (`velox/functions/prestosql/registration/MathematicalOperatorsRegistration.cpp`).
