# MULTIPLY

Category: [Arithmetic](../index.md#arithmetic) | Aliases: `*`

## Role and scenarios

Numeric multiplication (infix `*`). When DECIMAL operands participate, the precision and scale of the result are derived from the operands; when either operand is NULL, the result is NULL. It is used for quantity scaling, such as exchange-rate conversion, unit price times quantity, and weighted features.

## Usage

Signature: `a * b` (infix multiplication)

| Parameter | Type | Description |
|---|---|---|
| Left operand | Numeric | Multiplier |
| Right operand | Numeric | Multiplicand; when DECIMAL participates, the precision and scale of the result are derived from both operands |

Return: The product; the type is derived from the operands. NULL when either operand is NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.auction * 3 FROM bid;
```

Output: BIGINT; `auction * 3` for each row (varies with the row data).

Example (first 8 of the 16 source rows, illustrative data; leading columns are input columns, the last column is the result for that row):

| auction | auction * 3 | Notes |
|---|---|---|
| 3 | 9 | 3×3=9 |
| 19 | 57 | 19×3=57 |
| 8 | 24 | 8×3=24 |
| 1 | 3 | 1×3=3 |
| 14 | 42 | 14×3=42 |
| 7 | 21 | 7×3=21 |
| 11 | 33 | 11×3=33 |
| 20 | 60 | 20×3=60 |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | no dedicated operator-table entry; resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | the `TIMES` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | inlined by `ScalarOperatorGens` |

## Velox implementation

Velox already provides the builtin `multiply` (`velox/functions/prestosql/registration/MathematicalOperatorsRegistration.cpp`).
