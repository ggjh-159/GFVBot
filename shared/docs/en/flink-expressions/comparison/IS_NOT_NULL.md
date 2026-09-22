# IS_NOT_NULL

Category: [Comparison](../index.md#comparison) | Aliases: —

## Role and scenarios

The complement of IS NULL, likewise never returning UNKNOWN. Use it to filter rows before NULL-sensitive arithmetic or string functions.

## Usage

Signature: `x IS NOT NULL` (postfix predicate form)

| Parameter | Type | Description |
|---|---|---|
| x | Any nullable type | The value to test |

Return: BOOLEAN; TRUE when x is non-NULL; the result itself is never NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, (bid.auction IS NOT NULL) FROM bid;
```

Output: BOOLEAN; true on every row in this example — `auction` is a non-null column.

Example (first 8 rows of the 16-row source, illustrative data, with a final NULL-boundary row appended; leading columns are inputs, the last two are each row's result and notes):

| auction | auction IS NOT NULL | Notes |
|---|---|---|
| 3 | TRUE | Non-NULL value |
| 19 | TRUE | Non-NULL value |
| 8 | TRUE | Non-NULL value |
| 1 | TRUE | Non-NULL value |
| 14 | TRUE | Non-NULL value |
| 7 | TRUE | Non-NULL value |
| 11 | TRUE | Non-NULL value |
| 20 | TRUE | Non-NULL value |
| NULL | FALSE | NULL input yields FALSE; the result is never NULL |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | The `IS_NOT_NULL` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | The `IS_NOT_NULL` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | Inlined by `ScalarOperatorGens` |

## Velox implementation

Velox already provides an implementation: the sparksql suite's `isnotnull` (`velox/functions/sparksql/registration/RegisterComparison.cpp`) (the prestosql side registers only `is_null`).
