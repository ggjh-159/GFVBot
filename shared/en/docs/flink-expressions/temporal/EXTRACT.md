# EXTRACT

Category: [Temporal](../index.md#temporal) | Aliases: —

## Role and scenarios

Extracts the specified field — YEAR, QUARTER, MONTH, WEEK, DAY, DOY, DOW, HOUR, MINUTE, SECOND — from a date-time value and returns an integer. Useful for grouping by time bucket and deriving calendar features.

## Usage

Signature: `EXTRACT(field FROM ts)` — the SQL standard syntax form.

| Parameter | Type | Description |
|---|---|---|
| field | Keyword | The field to extract: YEAR, QUARTER, MONTH, WEEK, DAY, DOY, DOW, HOUR, MINUTE, SECOND |
| ts | DATE/TIME/TIMESTAMP (or interval) | The date-time value to extract from |

Return: BIGINT; the integer value of the extracted field.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, EXTRACT(DAY FROM bid.dateTime) FROM bid;
```

Output: BIGINT; the day of `dateTime`, 1-31 per row (varies with row data).

Examples (first 8 rows of the 16-row source, illustrative data):

| dateTime | EXTRACT(DAY FROM dateTime) | Notes |
|---|---|---|
| 2026-07-03 09:15:22.480 | 3 | Returns the day of that row's `dateTime`, in the range 1-31 |
| 2026-07-05 10:41:07.123 | 5 | Same as above |
| 2026-07-09 11:02:59.640 | 9 | Same as above |
| 2026-07-03 13:27:44.005 | 3 | Same as above |
| 2026-07-12 14:50:18.872 | 12 | Same as above |
| 2026-07-07 15:33:51.309 | 7 | Same as above |
| 2026-07-09 16:19:36.551 | 9 | Same as above |
| 2026-07-11 17:44:29.918 | 11 | Same as above |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `EXTRACT` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `EXTRACT` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | generated via `ExtractCallGen`, which calls `BuiltInMethods`.`UNIX_DATE_EXTRACT` (timestamps with time zone go through `EXTRACT_FROM_TIMESTAMP_TIME_ZONE`) |

## Velox implementation

GFV already implements `extract` on the velox side, registered in `velox/experimental/stateful/udf/Register.cpp` (implemented in `ExtractDateTime.h` in the same directory).
