# TIMESTAMPDIFF

Category: [Temporal](../index.md#temporal) | Aliases: —

## Role and scenarios

Returns the integer time difference expressed in the given unit — SECOND, MINUTE, HOUR, DAY, MONTH, or YEAR — in the direction t2 minus t1; month/year differences follow calendar arithmetic. Useful for computing latency, age, and duration.

## Usage

Signature: `TIMESTAMPDIFF(unit, t1, t2)`

| Parameter | Type | Description |
|---|---|---|
| unit | Keyword | The unit of the difference: SECOND, MINUTE, HOUR, DAY, MONTH, YEAR |
| t1 | Temporal type | The subtrahend side of the difference |
| t2 | Temporal type | The minuend side of the difference; must be the same temporal type as t1 |

Return: BIGINT; the integer difference expressed in unit, in the direction t2 minus t1.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, TIMESTAMPDIFF(SECOND, bid.dateTime, bid.dateTime) FROM bid;
```

Output: BIGINT; 0 on every row — both sides are the same timestamp.

Examples (first 8 rows of the 16-row source, illustrative data):

| dateTime | TIMESTAMPDIFF(SECOND, dateTime, dateTime) | Notes |
|---|---|---|
| 2026-07-03 09:15:22.480 | 0 | Both sides are the same timestamp; the difference is always 0 |
| 2026-07-05 10:41:07.123 | 0 | Same as above |
| 2026-07-09 11:02:59.640 | 0 | Same as above |
| 2026-07-03 13:27:44.005 | 0 | Same as above |
| 2026-07-12 14:50:18.872 | 0 | Same as above |
| 2026-07-07 15:33:51.309 | 0 | Same as above |
| 2026-07-09 16:19:36.551 | 0 | Same as above |
| 2026-07-11 17:44:29.918 | 0 | Same as above |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `TIMESTAMP_DIFF` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `TIMESTAMP_DIFF` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | generated via `TimestampDiffCallGen` — computes the unit difference between the two temporals with calendar semantics |

## Velox implementation

Velox already provides the builtin `date_diff` (`velox/functions/prestosql/registration/DateTimeFunctionsRegistration.cpp`) (unit-constant spellings differ from Flink's).
