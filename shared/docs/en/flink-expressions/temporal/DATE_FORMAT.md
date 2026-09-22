# DATE_FORMAT

Category: [Temporal](../index.md#temporal) | Aliases: —

## Role and scenarios

Formats a timestamp or time string using a Java SimpleDateFormat-style pattern (e.g. yyyy-MM-dd HH:mm:ss) and returns a STRING. Useful for fixed-width time labels in reports and partition columns.

## Usage

Signature: `DATE_FORMAT(ts, pattern)`

| Parameter | Type | Description |
|---|---|---|
| ts | TIMESTAMP/TIMESTAMP_LTZ/STRING | The timestamp or time string to format |
| pattern | STRING | A Java SimpleDateFormat-style pattern |

Return: STRING; the text rendered with the given pattern.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, DATE_FORMAT(bid.dateTime, 'yyyy-MM-dd HH:mm:ss') FROM bid;
```

Output: STRING; each row's `dateTime` rendered with the given pattern (varies with row data).

Examples (first 8 rows of the 16-row source, illustrative data):

| dateTime | DATE_FORMAT(dateTime, 'yyyy-MM-dd HH:mm:ss') | Notes |
|---|---|---|
| 2026-07-03 09:15:22.480 | 2026-07-03 09:15:22 | The pattern has no milliseconds; rendering stops at seconds |
| 2026-07-05 10:41:07.123 | 2026-07-05 10:41:07 | Same as above |
| 2026-07-09 11:02:59.640 | 2026-07-09 11:02:59 | Same as above |
| 2026-07-03 13:27:44.005 | 2026-07-03 13:27:44 | Same as above |
| 2026-07-12 14:50:18.872 | 2026-07-12 14:50:18 | Same as above |
| 2026-07-07 15:33:51.309 | 2026-07-07 15:33:51 | Same as above |
| 2026-07-09 16:19:36.551 | 2026-07-09 16:19:36 | Same as above |
| 2026-07-11 17:44:29.918 | 2026-07-11 17:44:29 | Same as above |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `DATE_FORMAT` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `DATE_FORMAT` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | static methods of `BuiltInMethods` (direct call via `MethodCallGen`) |

## Velox implementation

Velox already provides the builtin `date_format` (`velox/functions/prestosql/registration/DateTimeFunctionsRegistration.cpp`) (the sparksql suite also registers a function of the same name).
