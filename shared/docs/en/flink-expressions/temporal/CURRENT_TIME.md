# CURRENT_TIME

Category: [Temporal](../index.md#temporal) | Aliases: —

## Role and scenarios

Returns the current time of day, of type TIME; evaluated once per query, so all rows within the same query take the same value; written without parentheses. Useful for time-of-day routing based on the query instant.

## Usage

Signature: `CURRENT_TIME` — a time constant written without parentheses; type TIME.

No parameters.

Return: TIME; the time of day at the query instant, constant within the same query.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, CURRENT_TIME FROM bid;
```

Output: TIME; the time of day at the query instant, identical across all 16 rows.

Examples (input → output):

| Input | Output | Notes |
|---|---|---|
| — | 10:23:41 | Evaluated once per query; the 16 rows share one value |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | no dedicated operator-table entry; resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | the `CURRENT_TIME` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | via `CurrentTimePointCallGen` — in streaming mode injected as a reusable member holding a query-level constant; in batch mode folded at planning time |

## Velox implementation

The velox repository has no corresponding implementation yet.
