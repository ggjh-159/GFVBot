# LOCALTIME

Category: [Temporal](../index.md#temporal) | Aliases: —

## Role and scenarios

Returns the current local time of day, of type TIME (without time zone); evaluated once per query, so all rows within the same query take the same value; written without parentheses. Local time intended for presentation.

## Usage

Signature: `LOCALTIME` — a time constant written without parentheses; type TIME (without time zone).

No parameters.

Return: TIME; the local time of day at query start, constant within the same query.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, LOCALTIME FROM bid;
```

Output: TIME; the local time of day at query start, identical across all 16 rows.

Examples (input → output):

| Input | Output | Notes |
|---|---|---|
| — | 10:23:41 | Evaluated once per query; the 16 rows share one value |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | no dedicated operator-table entry; resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | the `LOCAL_TIME` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | via `CurrentTimePointCallGen` — in streaming mode injected as a reusable member holding a query-level constant; in batch mode folded at planning time |

## Velox implementation

The velox repository has no corresponding implementation yet.
