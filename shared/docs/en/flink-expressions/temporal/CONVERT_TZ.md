# CONVERT_TZ

Category: [Temporal](../index.md#temporal) | Aliases: —

## Role and scenarios

Converts a timestamp string without time zone from one time zone to another, returning the converted time string. Time zone names are ids from `java.util.TimeZone`. Useful for ingesting local-time data into a UTC pipeline, or for the reverse conversion.

## Usage

Signature: `CONVERT_TZ(ts, fromTz, toTz)`

| Parameter | Type | Description |
|---|---|---|
| ts | STRING | Timestamp string without time zone |
| fromTz | STRING | Source time zone, an id from `java.util.TimeZone` |
| toTz | STRING | Target time zone, an id from `java.util.TimeZone` |

Return: STRING; the time string converted into the target time zone.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, CONVERT_TZ('2026-09-11 10:00:00', 'UTC', 'Asia/Shanghai') FROM bid;
```

Output: STRING; every row is '2026-09-11 18:00:00'.

Examples (input → output):

| Input | Output | Notes |
|---|---|---|
| CONVERT_TZ('2026-09-11 10:00:00', 'UTC', 'Asia/Shanghai') | 2026-09-11 18:00:00 | 10:00 UTC converts to 18:00 in Asia/Shanghai (UTC+8) |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `CONVERT_TZ` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `CONVERT_TZ` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | static methods of `BuiltInMethods` (direct call via `MethodCallGen`) |

## Velox implementation

The velox repository has no corresponding implementation yet.
