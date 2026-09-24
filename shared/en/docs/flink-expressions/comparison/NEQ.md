# NEQ

Category: [Comparison](../index.md#comparison) | Aliases: `<>`, `!=`

## Role and scenarios

Negation of equals: returns TRUE when the two operands are unequal; UNKNOWN when either side is NULL. Used to exclude specific values and to detect differences by comparing two columns, or a column against a constant.

## Usage

Signature: `a <> b` (infix form; may also be written `a != b`)

| Parameter | Type | Description |
|---|---|---|
| Left operand | Comparable type | Numeric, string, boolean, temporal, etc. |
| Right operand | Comparable type | Mutually comparable with the left operand |

Return: BOOLEAN; TRUE when unequal, FALSE when equal; UNKNOWN when either side is NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.auction <> bid.bidder FROM bid;
```

Output: BOOLEAN; true when `auction` is not equal to `bidder` (varies with row data).

Example (first 8 rows of the 16-row source, illustrative data, with a final NULL-boundary row appended; leading columns are inputs, the last two are each row's result and notes):

| auction | bidder | auction <> bidder | Notes |
|---|---|---|---|
| 3 | 15 | TRUE | Not equal |
| 19 | 7 | TRUE | Not equal |
| 8 | 8 | FALSE | Equal |
| 1 | 42 | TRUE | Not equal |
| 14 | 23 | TRUE | Not equal |
| 7 | 2 | TRUE | Not equal |
| 11 | 11 | FALSE | Equal |
| 20 | 36 | TRUE | Not equal |
| NULL | 8 | UNKNOWN | Either side NULL yields UNKNOWN |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | The `NOT_EQUALS` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | The `NOT_EQUALS` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | Inlined by `ScalarOperatorGens` |

## Velox implementation

Velox already provides the builtin `neq` (`velox/functions/prestosql/registration/ComparisonFunctionsRegistration.cpp`).
