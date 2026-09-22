# CURRENT_DATE

Category: [Temporal](../index.md#temporal) | Aliases: —

## Role and scenarios

Returns the current SQL date in the session time zone, of type DATE; evaluated once per query, so all rows within the same query take the same value. Useful for partition-day filtering and arrival-day tagging.

## Usage

Signature: `CURRENT_DATE` — a time constant written without parentheses; type DATE.

No parameters.

Return: DATE; the date of the query day, constant within the same query.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, CURRENT_DATE FROM bid;
```

Output: DATE; the date of the query day, identical across all 16 rows.

Examples (input → output):

| Input | Output | Notes |
|---|---|---|
| — | 2026-09-11 | Evaluated once per query; the 16 rows share one value |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | no dedicated operator-table entry; resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | the `CURRENT_DATE` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | via `CurrentTimePointCallGen` — in streaming mode injected as a reusable member holding a query-level constant; in batch mode folded at planning time |

## Velox implementation

Velox already provides the builtin `current_date` (`velox/functions/prestosql/registration/DateTimeFunctionsRegistration.cpp`).
