# UNARY_MINUS

Category: [Arithmetic](../index.md#arithmetic) | Aliases: `-x`

## Role and scenarios

Unary negation of a numeric value (prefix `-x`), with the result type identical to the operand; a NULL input still yields NULL. It is used to flip the sign of a metric so that difference directions become more intuitive (e.g. losses, lateness).

## Usage

Signature: `-x` (prefix negation)

| Parameter | Type | Description |
|---|---|---|
| x | Numeric | Operand to negate; any numeric type |

Return: Same type as the operand; NULL when the input is NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, -bid.auction FROM bid;
```

Output: BIGINT; the negated `auction` of each row.

Example (first 8 of the 16 source rows, illustrative data; leading columns are input columns, the last column is the result for that row):

| auction | -auction | Notes |
|---|---|---|
| 3 | -3 | The opposite of 3 |
| 19 | -19 | The opposite of 19 |
| 8 | -8 | The opposite of 8 |
| 1 | -1 | The opposite of 1 |
| 14 | -14 | The opposite of 14 |
| 7 | -7 | The opposite of 7 |
| 11 | -11 | The opposite of 11 |
| 20 | -20 | The opposite of 20 |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | no dedicated operator-table entry; resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | the `MINUS_PREFIX` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | inlined by `ScalarOperatorGens` |

## Velox implementation

Velox already provides the builtin `negate` (`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`).
