# IS_FALSE

Category: [Logical](../index.md#logical) | Aliases: —

## Role and scenarios

Returns TRUE only when the input is exactly FALSE — UNKNOWN differs from FALSE and also yields FALSE here. Wherever distinguishing false from unknown matters (for example anti-joins, NOT semantics), this is the precise test.

## Usage

Signature: `x IS FALSE` (postfix predicate form)

| Parameter | Type | Description |
|---|---|---|
| x | BOOLEAN | May be NULL |

Return: BOOLEAN; TRUE only when x is exactly FALSE, and FALSE also when x is UNKNOWN; the result is never NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, (bid.auction > 10 IS FALSE) FROM bid;
```

Output: BOOLEAN; true only when `auction > 10` is exactly false.

Example (first 8 rows of the 16-row source, illustrative data, with a final three-valued-logic boundary row appended; leading columns are inputs, the last two are each row's result and notes):

| auction | auction > 10 IS FALSE | Notes |
|---|---|---|
| 3 | TRUE | Inner FALSE |
| 19 | FALSE | Inner TRUE |
| 8 | TRUE | Inner FALSE |
| 1 | TRUE | Inner FALSE |
| 14 | FALSE | Inner TRUE |
| 7 | TRUE | Inner FALSE |
| 11 | FALSE | Inner TRUE |
| 20 | FALSE | Inner TRUE |
| NULL | FALSE | Inner UNKNOWN, which is not FALSE |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | The `IS_FALSE` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | The `IS_FALSE` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | Inlined by `ScalarOperatorGens` |

## Velox implementation

The velox repository has no corresponding implementation yet.
