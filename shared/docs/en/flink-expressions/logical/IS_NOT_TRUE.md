# IS_NOT_TRUE

Category: [Logical](../index.md#logical) | Aliases: —

## Role and scenarios

Returns TRUE when the input is FALSE or UNKNOWN — that is, every value other than exactly TRUE. Useful wherever UNKNOWN should be handled as not true (for example negated filtering).

## Usage

Signature: `x IS NOT TRUE` (postfix predicate form)

| Parameter | Type | Description |
|---|---|---|
| x | BOOLEAN | May be NULL |

Return: BOOLEAN; TRUE when x is FALSE or UNKNOWN; the result is never NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, (bid.auction > 10 IS NOT TRUE) FROM bid;
```

Output: BOOLEAN; true when `auction > 10` is false or unknown.

Example (first 8 rows of the 16-row source, illustrative data, with a final three-valued-logic boundary row appended; leading columns are inputs, the last two are each row's result and notes):

| auction | auction > 10 IS NOT TRUE | Notes |
|---|---|---|
| 3 | TRUE | Inner FALSE, which is not TRUE |
| 19 | FALSE | Inner TRUE |
| 8 | TRUE | Inner FALSE, which is not TRUE |
| 1 | TRUE | Inner FALSE, which is not TRUE |
| 14 | FALSE | Inner TRUE |
| 7 | TRUE | Inner FALSE, which is not TRUE |
| 11 | FALSE | Inner TRUE |
| 20 | FALSE | Inner TRUE |
| NULL | TRUE | Inner UNKNOWN, which is not TRUE |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | The `IS_NOT_TRUE` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | The `IS_NOT_TRUE` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | Inlined by `ScalarOperatorGens` |

## Velox implementation

The velox repository has no corresponding implementation yet.
