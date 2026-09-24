# EQ

Category: [Comparison](../index.md#comparison) | Aliases: `=`

## Role and scenarios

Compares two operands for equality and returns TRUE when they are equal; when either side is NULL the result is UNKNOWN, which in a WHERE clause is treated as not satisfied. The most fundamental SQL predicate, widely used in equality filtering, JOIN conditions, and CASE branches.

## Usage

Signature: `a = b` (infix form)

| Parameter | Type | Description |
|---|---|---|
| Left operand | Comparable type | Numeric, string, boolean, temporal, etc. |
| Right operand | Comparable type | Mutually comparable with the left operand |

Return: BOOLEAN; TRUE when equal, otherwise FALSE; UNKNOWN when either side is NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.auction = bid.bidder FROM bid;
```

Output: BOOLEAN; one value per row, true when `auction` equals `bidder` (varies with row data).

Example (first 8 rows of the 16-row source, illustrative data, with a final NULL-boundary row appended; leading columns are inputs, the last two are each row's result and notes):

| auction | bidder | auction = bidder | Notes |
|---|---|---|---|
| 3 | 15 | FALSE | Not equal |
| 19 | 7 | FALSE | Not equal |
| 8 | 8 | TRUE | Equal |
| 1 | 42 | FALSE | Not equal |
| 14 | 23 | FALSE | Not equal |
| 7 | 2 | FALSE | Not equal |
| 11 | 11 | TRUE | Equal |
| 20 | 36 | FALSE | Not equal |
| NULL | 8 | UNKNOWN | Either side NULL yields UNKNOWN |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | The `EQUALS` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | The `EQUALS` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | Inlined by `ScalarOperatorGens` |

## Velox implementation

Velox already provides the builtin `eq` (`velox/functions/prestosql/registration/ComparisonFunctionsRegistration.cpp`).
