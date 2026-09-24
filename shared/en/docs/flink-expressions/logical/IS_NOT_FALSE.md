# IS_NOT_FALSE

Category: [Logical](../index.md#logical) | Aliases: —

## Role and scenarios

Returns TRUE when the input is TRUE or UNKNOWN — that is, every value other than exactly FALSE. The mirror of IS NOT TRUE, used to treat UNKNOWN as not false.

## Usage

Signature: `x IS NOT FALSE` (postfix predicate form)

| Parameter | Type | Description |
|---|---|---|
| x | BOOLEAN | May be NULL |

Return: BOOLEAN; TRUE when x is TRUE or UNKNOWN; the result is never NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, (bid.auction > 10 IS NOT FALSE) FROM bid;
```

Output: BOOLEAN; true when `auction > 10` is true or unknown.

Example (first 8 rows of the 16-row source, illustrative data, with a final three-valued-logic boundary row appended; leading columns are inputs, the last two are each row's result and notes):

| auction | auction > 10 IS NOT FALSE | Notes |
|---|---|---|
| 3 | FALSE | Inner FALSE |
| 19 | TRUE | Inner TRUE, which is not FALSE |
| 8 | FALSE | Inner FALSE |
| 1 | FALSE | Inner FALSE |
| 14 | TRUE | Inner TRUE, which is not FALSE |
| 7 | FALSE | Inner FALSE |
| 11 | TRUE | Inner TRUE, which is not FALSE |
| 20 | TRUE | Inner TRUE, which is not FALSE |
| NULL | TRUE | Inner UNKNOWN, which is not FALSE |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | The `IS_NOT_FALSE` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | The `IS_NOT_FALSE` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | Inlined by `ScalarOperatorGens` |

## Velox implementation

The velox repository has no corresponding implementation yet.
