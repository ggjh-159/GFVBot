# NOT

Category: [Logical](../index.md#logical) | Aliases: —

## Role and scenarios

Logical negation: TRUE becomes FALSE and FALSE becomes TRUE; UNKNOWN stays UNKNOWN. NOT binds lower than comparison predicates, so wrap compound conditions in parentheses as a whole to avoid ambiguity.

## Usage

Signature: `NOT x` (unary prefix form)

| Parameter | Type | Description |
|---|---|---|
| x | BOOLEAN | The boolean expression to negate; compound conditions should be parenthesized |

Return: BOOLEAN; TRUE and FALSE are swapped; when the input is NULL (UNKNOWN) the result stays UNKNOWN.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, NOT (bid.auction > 5) FROM bid;
```

Output: BOOLEAN; each row negates `auction > 5` (varies with row data).

Example (first 8 rows of the 16-row source, illustrative data, with a final NULL-boundary row appended; leading columns are inputs, the last two are each row's result and notes):

| auction | NOT (auction > 5) | Notes |
|---|---|---|
| 3 | TRUE | Inner FALSE, negated to TRUE |
| 19 | FALSE | Inner TRUE, negated to FALSE |
| 8 | FALSE | Inner TRUE, negated to FALSE |
| 1 | TRUE | Inner FALSE, negated to TRUE |
| 14 | FALSE | Inner TRUE, negated to FALSE |
| 7 | FALSE | Inner TRUE, negated to FALSE |
| 11 | FALSE | Inner TRUE, negated to FALSE |
| 20 | FALSE | Inner TRUE, negated to FALSE |
| NULL | UNKNOWN | Inner UNKNOWN; negation stays UNKNOWN |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | The `NOT` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | The `NOT` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | Inlined by `ScalarOperatorGens` |

## Velox implementation

Velox already provides the builtin `not` (`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`).
