# IS_TRUE

Category: [Logical](../index.md#logical) | Aliases: —

## Role and scenarios

Collapses three-valued logic to two-valued: returns TRUE only when the input is exactly TRUE; both FALSE and UNKNOWN map to FALSE. Equivalent to an explicit spelling that treats UNKNOWN as FALSE.

## Usage

Signature: `x IS TRUE` (postfix predicate form)

| Parameter | Type | Description |
|---|---|---|
| x | BOOLEAN | May be NULL |

Return: BOOLEAN; TRUE only when x is exactly TRUE; the result is never NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, (bid.auction > 10 IS TRUE) FROM bid;
```

Output: BOOLEAN; the truth value of `auction > 10` on each row (varies with row data).

Example (first 8 rows of the 16-row source, illustrative data, with a final three-valued-logic boundary row appended; leading columns are inputs, the last two are each row's result and notes):

| auction | auction > 10 IS TRUE | Notes |
|---|---|---|
| 3 | FALSE | Inner FALSE |
| 19 | TRUE | Inner TRUE |
| 8 | FALSE | Inner FALSE |
| 1 | FALSE | Inner FALSE |
| 14 | TRUE | Inner TRUE |
| 7 | FALSE | Inner FALSE |
| 11 | TRUE | Inner TRUE |
| 20 | TRUE | Inner TRUE |
| NULL | FALSE | Inner UNKNOWN, mapped to FALSE |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | The `IS_TRUE` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | The `IS_TRUE` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | Inlined by `ScalarOperatorGens` |

## Velox implementation

The velox repository has no corresponding implementation yet.
