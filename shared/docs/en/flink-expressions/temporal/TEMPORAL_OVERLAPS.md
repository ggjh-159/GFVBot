# TEMPORAL_OVERLAPS

Category: [Temporal](../index.md#temporal) | Aliases: `OVERLAPS`

## Role and scenarios

Tests whether two time intervals share a common instant: `(s1, e1) OVERLAPS (s2, e2)`; each side may be a (start, end) pair or a (start, duration) pair. Commonly used for schedule-conflict detection and window-overlap checks.

## Usage

Signature: `(s1, e1 | iv1) OVERLAPS (s2, e2 | iv2)` — infix predicate form.

| Parameter | Type | Description |
|---|---|---|
| s1, s2 | Temporal types | The start points of the two intervals |
| e1, e2 | Temporal type or INTERVAL | The interval end points, or durations added to the start points |

Return: BOOLEAN; TRUE when the two intervals share a common instant.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, (bid.dateTime, INTERVAL '1' HOUR) OVERLAPS (bid.dateTime, INTERVAL '1' DAY) FROM bid;
```

Output: BOOLEAN; constantly true in this example — both windows start at `dateTime`, and the 1-hour window is fully contained by the 1-day window.

Examples (first 8 rows of the 16-row source, illustrative data):

| dateTime | (dateTime, 1h) OVERLAPS (dateTime, 1d) | Notes |
|---|---|---|
| 2026-07-03 09:15:22.480 | TRUE | Both windows start at that row's `dateTime`; the 1-hour window is fully contained by the 1-day window |
| 2026-07-05 10:41:07.123 | TRUE | Same as above |
| 2026-07-09 11:02:59.640 | TRUE | Same as above |
| 2026-07-03 13:27:44.005 | TRUE | Same as above |
| 2026-07-12 14:50:18.872 | TRUE | Same as above |
| 2026-07-07 15:33:51.309 | TRUE | Same as above |
| 2026-07-09 16:19:36.551 | TRUE | Same as above |
| 2026-07-11 17:44:29.918 | TRUE | Same as above |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this expression in GFV:

| Stage | Location |
|---|---|
| Parser recognition | no dedicated operator-table entry; resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | the `TEMPORAL_OVERLAPS` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `TemporalOverlapsConverter` expands OVERLAPS into an AND/OR comparison tree over the interval boundaries, inlined via `ScalarOperatorGens` |

## Velox implementation

The velox repository has no corresponding implementation yet.
