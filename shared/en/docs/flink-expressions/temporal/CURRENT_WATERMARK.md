# CURRENT_WATERMARK

Category: [Temporal](../index.md#temporal) | Aliases: —

## Role and scenarios

Returns the current event-time watermark of the given rowtime attribute, of type TIMESTAMP_LTZ. Returns NULL while the watermark has not yet advanced, and is always NULL for an ordinary non-rowtime column — the argument must be a time column declared as an event-time attribute. Useful for debugging watermark progress and writing watermark-aware logic.

## Usage

Signature: `CURRENT_WATERMARK(rowtime)`

| Parameter | Type | Description |
|---|---|---|
| rowtime | Time attribute column | Must be an event-time (rowtime) attribute |

Return: TIMESTAMP_LTZ or NULL; NULL when the watermark has not yet advanced or the argument is not a rowtime attribute.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, CURRENT_WATERMARK(bid.dateTime) FROM bid;
```

Output: TIMESTAMP_LTZ or NULL; NULL on every row in this example — `dateTime` is not a rowtime attribute.

Examples (first 8 rows of the 16-row source, illustrative data):

| dateTime | CURRENT_WATERMARK(dateTime) | Notes |
|---|---|---|
| 2026-07-03 09:15:22.480 | NULL | `dateTime` is not a rowtime attribute; always NULL |
| 2026-07-05 10:41:07.123 | NULL | Same as above |
| 2026-07-09 11:02:59.640 | NULL | Same as above |
| 2026-07-03 13:27:44.005 | NULL | Same as above |
| 2026-07-12 14:50:18.872 | NULL | Same as above |
| 2026-07-07 15:33:51.309 | NULL | Same as above |
| 2026-07-09 16:19:36.551 | NULL | Same as above |
| 2026-07-11 17:44:29.918 | NULL | Same as above |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | no dedicated operator-table entry; resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | the `CURRENT_WATERMARK` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | special-cased in `ExprCodeGenerator` — reads the current watermark from the input StreamRecord context |

## Velox implementation

The velox repository has no corresponding implementation yet (it queries operator watermark state).
