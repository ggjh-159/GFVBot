# LT

Category: [Comparison](../index.md#comparison) | Aliases: `<`

## Role and scenarios

Ordering predicate: returns TRUE when the left operand is strictly less than the right; UNKNOWN when either side is NULL. Commonly used for range filtering, boundary checks, and magnitude comparison between two columns.

## Usage

Signature: `a < b` (infix form)

| Parameter | Type | Description |
|---|---|---|
| Left operand | Comparable, orderable type | Numeric, string, temporal, etc. |
| Right operand | Comparable, orderable type | Mutually comparable with the left operand |

Return: BOOLEAN; TRUE when the left operand is strictly less than the right; UNKNOWN when either side is NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.auction < bid.bidder FROM bid;
```

Output: BOOLEAN; true when `auction` is less than `bidder` (varies with row data).

Example (first 8 rows of the 16-row source, illustrative data, with a final NULL-boundary row appended; leading columns are inputs, the last two are each row's result and notes):

| auction | bidder | auction < bidder | Notes |
|---|---|---|---|
| 3 | 15 | TRUE | Less than holds |
| 19 | 7 | FALSE | Not less |
| 8 | 8 | FALSE | Equal does not count as less |
| 1 | 42 | TRUE | Less than holds |
| 14 | 23 | TRUE | Less than holds |
| 7 | 2 | FALSE | Not less |
| 11 | 11 | FALSE | Equal does not count as less |
| 20 | 36 | TRUE | Less than holds |
| NULL | 8 | UNKNOWN | Either side NULL yields UNKNOWN |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | The `LESS_THAN` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | The `LESS_THAN` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | Inlined by `ScalarOperatorGens` |

## Velox implementation

Velox already provides the builtin `lt` (`velox/functions/prestosql/registration/ComparisonFunctionsRegistration.cpp`).
