# OR

Category: [Logical](../index.md#logical) | Aliases: —

## Role and scenarios

Logical disjunction under three-valued logic: TRUE as soon as either operand is TRUE; FALSE only when both are FALSE; UNKNOWN otherwise. Used to loosen filter conditions and to express alternatives.

## Usage

Signature: `a OR b` (infix form)

| Parameter | Type | Description |
|---|---|---|
| Left operand | BOOLEAN | May be NULL; participates under three-valued logic |
| Right operand | BOOLEAN | May be NULL; participates under three-valued logic |

Return: BOOLEAN; TRUE when either operand is TRUE, FALSE only when both are FALSE, UNKNOWN otherwise (`NULL OR TRUE` is TRUE, `NULL OR FALSE` is UNKNOWN).

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, (bid.auction > 15) OR (bid.bidder < 10) FROM bid;
```

Output: BOOLEAN; true when `auction > 15` or `bidder < 10` holds (varies with row data).

Example (first 8 rows of the 16-row source, illustrative data, with two final three-valued-logic boundary rows appended; leading columns are inputs, the last two are each row's result and notes):

| auction | bidder | (auction > 15) OR (bidder < 10) | Notes |
|---|---|---|---|
| 3 | 15 | FALSE | Both sides FALSE |
| 19 | 7 | TRUE | Both sides TRUE |
| 8 | 8 | TRUE | Right side TRUE |
| 1 | 42 | FALSE | Both sides FALSE |
| 14 | 23 | FALSE | Both sides FALSE |
| 7 | 2 | TRUE | Right side TRUE |
| 11 | 11 | FALSE | Both sides FALSE |
| 20 | 36 | TRUE | Left side TRUE |
| NULL | 7 | TRUE | Right side TRUE prevails over UNKNOWN |
| NULL | 42 | UNKNOWN | Left side UNKNOWN and right side FALSE, so UNKNOWN |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | The `OR` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | The `OR` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | Inlined by `ScalarOperatorGens` |

## Velox implementation

The velox expression kernel handles it as the special form `or` (`velox/expression/RegisterSpecialForm.cpp`), with no standalone function registration.
