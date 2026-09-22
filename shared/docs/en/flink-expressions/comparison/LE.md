# LE

Category: [Comparison](../index.md#comparison) | Aliases: `<=`

## Role and scenarios

Ordering predicate: returns TRUE when the left operand is less than or equal to the right; UNKNOWN when either side is NULL. Commonly serves as the closed lower bound of a range filter.

## Usage

Signature: `a <= b` (infix form)

| Parameter | Type | Description |
|---|---|---|
| Left operand | Comparable, orderable type | Numeric, string, temporal, etc. |
| Right operand | Comparable, orderable type | Mutually comparable with the left operand |

Return: BOOLEAN; TRUE when the left operand is less than or equal to the right; UNKNOWN when either side is NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.auction <= bid.bidder FROM bid;
```

Output: BOOLEAN; true when `auction` is not greater than `bidder` (varies with row data).

Example (first 8 rows of the 16-row source, illustrative data, with a final NULL-boundary row appended; leading columns are inputs, the last two are each row's result and notes):

| auction | bidder | auction <= bidder | Notes |
|---|---|---|---|
| 3 | 15 | TRUE | Less than holds |
| 19 | 7 | FALSE | Greater than |
| 8 | 8 | TRUE | Equal hits the closed boundary |
| 1 | 42 | TRUE | Less than holds |
| 14 | 23 | TRUE | Less than holds |
| 7 | 2 | FALSE | Greater than |
| 11 | 11 | TRUE | Equal hits the closed boundary |
| 20 | 36 | TRUE | Less than holds |
| NULL | 8 | UNKNOWN | Either side NULL yields UNKNOWN |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | The `LESS_THAN_OR_EQUAL` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | The `LESS_THAN_OR_EQUAL` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | Inlined by `ScalarOperatorGens` |

## Velox implementation

Velox already provides the builtin `lte` (`velox/functions/prestosql/registration/ComparisonFunctionsRegistration.cpp`).
