# TO_DATE

Category: [Temporal](../index.md#temporal) | Aliases: —

## Role and scenarios

Parses a date string into a DATE, with default format yyyy-MM-dd. Useful for turning text dates into values usable for date arithmetic and partitioning.

## Usage

Signature: `TO_DATE(s[, format])`

| Parameter | Type | Description |
|---|---|---|
| s | STRING | Date string in the default format yyyy-MM-dd |
| format | STRING | Optional parsing format |

Return: DATE; the parsed date value.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, TO_DATE('2026-09-11') FROM bid;
```

Output: DATE; every row is 2026-09-11.

Examples (input → output):

| Input | Output | Notes |
|---|---|---|
| TO_DATE('2026-09-11') | 2026-09-11 | Parsed with the default format yyyy-MM-dd |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `TO_DATE` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `TO_DATE` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | static methods of `BuiltInMethods` (direct call via `MethodCallGen`) |

## Velox implementation

The velox repository has no corresponding implementation yet.
