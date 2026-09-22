# AND

Category: [Logical](../index.md#logical) | Aliases: —

## Role and scenarios

Logical conjunction under three-valued logic: TRUE only when both operands are TRUE; FALSE as soon as either is FALSE; UNKNOWN otherwise. The basic building block of compound WHERE, JOIN, and HAVING predicates.

## Usage

Signature: `a AND b` (infix form)

| Parameter | Type | Description |
|---|---|---|
| Left operand | BOOLEAN | May be NULL; participates under three-valued logic |
| Right operand | BOOLEAN | May be NULL; participates under three-valued logic |

Return: BOOLEAN; TRUE when both operands are TRUE, FALSE when either is FALSE, UNKNOWN otherwise (`NULL AND FALSE` is FALSE, `NULL AND TRUE` is UNKNOWN).

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, (bid.auction > 5) AND (bid.bidder < 40) FROM bid;
```

Output: BOOLEAN; true when `auction > 5` and `bidder < 40` both hold (varies with row data).

Example (first 8 rows of the 16-row source, illustrative data, with two final three-valued-logic boundary rows appended; leading columns are inputs, the last two are each row's result and notes):

| auction | bidder | (auction > 5) AND (bidder < 40) | Notes |
|---|---|---|---|
| 3 | 15 | FALSE | Left side FALSE, so directly FALSE |
| 19 | 7 | TRUE | Both sides TRUE |
| 8 | 8 | TRUE | Both sides TRUE |
| 1 | 42 | FALSE | Both sides FALSE |
| 14 | 23 | TRUE | Both sides TRUE |
| 7 | 2 | TRUE | Both sides TRUE |
| 11 | 11 | TRUE | Both sides TRUE |
| 20 | 36 | TRUE | Both sides TRUE |
| NULL | 15 | UNKNOWN | Left side UNKNOWN and right side TRUE, so UNKNOWN |
| NULL | 42 | FALSE | Right side FALSE; FALSE prevails over UNKNOWN, so FALSE |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | The `AND` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | The `AND` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | Inlined by `ScalarOperatorGens` |

## Velox implementation

The velox expression kernel handles it as the special form `and` (`velox/expression/RegisterSpecialForm.cpp`), with no standalone function registration.
