# NOW

Category: [Temporal](../index.md#temporal) | Aliases: `CURRENT_TIMESTAMP`

## Role and scenarios

Synonymous with CURRENT_TIMESTAMP — returns the TIMESTAMP_LTZ of the current instant, rendered in the session time zone, evaluated once per query — but must be written with parentheses as `NOW()`.

## Usage

Signature: `NOW()` — parentheses required; synonymous with `CURRENT_TIMESTAMP`.

No parameters.

Return: TIMESTAMP_LTZ; one instant fixed for the entire query, rendered in the session time zone.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, NOW() FROM bid;
```

Output: TIMESTAMP_LTZ; one instant fixed for the entire query — identical across all 16 rows.

Examples (input → output):

| Input | Output | Notes |
|---|---|---|
| — | 2026-09-11 10:23:41.209 | Evaluated once per query; the 16 rows share one value |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | no dedicated operator-table entry; resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | the `NOW` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | via `CurrentTimePointCallGen` — the same carrier as CURRENT_TIMESTAMP; in streaming mode injected as a query-level constant |

## Velox implementation

Velox already provides an implementation: the sparksql suite's `current_timestamp` (`velox/functions/sparksql/registration/RegisterDatetime.cpp`) (this is the counterpart of NOW).
