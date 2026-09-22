# TO_TIMESTAMP

Category: [Temporal](../index.md#temporal) | Aliases: —

## Role and scenarios

Parses a timestamp string into a TIMESTAMP, with default format yyyy-MM-dd HH:mm:ss, interpreting the text in the session time zone. Useful for turning text timestamps into values that can be windowed.

## Usage

Signature: `TO_TIMESTAMP(s[, format])`

| Parameter | Type | Description |
|---|---|---|
| s | STRING | Timestamp string in the default format yyyy-MM-dd HH:mm:ss |
| format | STRING | Optional parsing format |

Return: TIMESTAMP; the parsed timestamp value.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, TO_TIMESTAMP('2026-09-11 10:00:00') FROM bid;
```

Output: TIMESTAMP; every row is 2026-09-11 10:00:00.

Examples (input → output):

| Input | Output | Notes |
|---|---|---|
| TO_TIMESTAMP('2026-09-11 10:00:00') | 2026-09-11 10:00:00 | Parsed with the default format yyyy-MM-dd HH:mm:ss |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `TO_TIMESTAMP` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `TO_TIMESTAMP` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | static methods of `BuiltInMethods` (direct call via `MethodCallGen`) |

## Velox implementation

The velox repository has no corresponding implementation yet.
