# IS_NULL

Category: [Comparison](../index.md#comparison) | Aliases: —

## Role and scenarios

Tests whether a value is NULL, returning a plain TRUE or FALSE and never UNKNOWN, which makes it the only reliable way to filter nulls. Commonly used for data-quality checks and to guard expressions that would propagate NULL.

## Usage

Signature: `x IS NULL` (postfix predicate form)

| Parameter | Type | Description |
|---|---|---|
| x | Any nullable type | The value to test |

Return: BOOLEAN; TRUE when x is NULL, otherwise FALSE; the result itself is never NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, (bid.auction IS NULL) FROM bid;
```

Output: BOOLEAN; false on every row in this example — `auction` is a non-null column.

Example (first 8 rows of the 16-row source, illustrative data, with a final NULL-boundary row appended; leading columns are inputs, the last two are each row's result and notes):

| auction | auction IS NULL | Notes |
|---|---|---|
| 3 | FALSE | Non-NULL value |
| 19 | FALSE | Non-NULL value |
| 8 | FALSE | Non-NULL value |
| 1 | FALSE | Non-NULL value |
| 14 | FALSE | Non-NULL value |
| 7 | FALSE | Non-NULL value |
| 11 | FALSE | Non-NULL value |
| 20 | FALSE | Non-NULL value |
| NULL | TRUE | NULL input yields TRUE; the result is never NULL |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | The `IS_NULL` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | The `IS_NULL` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | Inlined by `ScalarOperatorGens` |

## Velox implementation

Velox already provides the builtin `is_null` (`velox/functions/prestosql/registration/GeneralFunctionsRegistration.cpp`); the sparksql suite also registers `isnull`.
