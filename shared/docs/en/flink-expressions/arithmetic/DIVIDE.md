# DIVIDE

Category: [Arithmetic](../index.md#arithmetic) | Aliases: `/`

## Role and scenarios

Numeric division (infix `/`): dividing integer operands returns DOUBLE, and Flink performs no truncating integer division; DECIMAL divided by DECIMAL returns a DECIMAL derived by precision inference. When either operand is NULL, the result is NULL. It is used for ratios and unit measures.

## Usage

Signature: `a / b` (infix division)

| Parameter | Type | Description |
|---|---|---|
| Left operand | Numeric | Dividend |
| Right operand | Numeric | Divisor |

Return: Dividing integer operands yields DOUBLE; dividing DECIMAL operands yields a DECIMAL derived by precision inference. NULL when either operand is NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.auction / 7 FROM bid;
```

Output: DOUBLE; `auction / 7` for each row, e.g. 3 / 7 = 0.42857142857142855.

Example (first 8 of the 16 source rows, illustrative data; leading columns are input columns, the last column is the result for that row):

| auction | auction / 7 | Notes |
|---|---|---|
| 3 | 0.42857142857142855 | The quotient is less than 1; the full fraction is kept |
| 19 | 2.7142857142857144 | Not evenly divisible; the quotient is the DOUBLE approximation of an infinitely repeating decimal |
| 8 | 1.1428571428571428 | Not evenly divisible |
| 1 | 0.14285714285714285 | The quotient is less than 1 |
| 14 | 2.0 | Evenly divisible; the result is still DOUBLE |
| 7 | 1.0 | Evenly divisible; the result is still DOUBLE |
| 11 | 1.5714285714285714 | Not evenly divisible |
| 20 | 2.857142857142857 | Not evenly divisible |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `DIVIDE` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `DIVIDE` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | numeric division is inlined by `ScalarOperatorGens`; DECIMAL division takes the precision-preserving route of `DivCallGen` |

## Velox implementation

Velox already provides the builtin `divide` (`velox/functions/prestosql/registration/MathematicalOperatorsRegistration.cpp`).
