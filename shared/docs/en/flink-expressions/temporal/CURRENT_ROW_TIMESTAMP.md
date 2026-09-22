# CURRENT_ROW_TIMESTAMP

Category: [Temporal](../index.md#temporal) | Aliases: —

## Role and scenarios

Returns a TIMESTAMP_LTZ clock that is read row by row at evaluation time — whereas CURRENT_TIMESTAMP fixes one instant per query. In Flink 1.19 the parentheses are mandatory; without them the parser treats it as a column name. Useful for ingestion-time tagging.

## Usage

Signature: `CURRENT_ROW_TIMESTAMP()` — parentheses required.

No parameters.

Return: TIMESTAMP_LTZ; the clock is read anew for each row, non-deterministic.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, CURRENT_ROW_TIMESTAMP() FROM bid;
```

Output: TIMESTAMP_LTZ; read anew on every row.

Examples (input → output):

| Input | Output | Notes |
|---|---|---|
| — | 2026-09-11 10:23:41.209 | Regenerated on every row (non-deterministic); the value shown is one sampled draw |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `CURRENT_ROW_TIMESTAMP` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `CURRENT_ROW_TIMESTAMP` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | the row-by-row mode of `CurrentTimePointCallGen` — reads the clock on every row |

## Velox implementation

The velox repository has no corresponding implementation yet.
