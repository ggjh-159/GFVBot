# PROCTIME

Category: [Temporal](../index.md#temporal) | Aliases: —

## Role and scenarios

Dual identity: in DDL, `AS PROCTIME()` marks a column as a processing-time attribute; inside a query body, `PROCTIME()` evaluates row by row to the current processing time, of type TIMESTAMP_LTZ. Used for TTL decisions, late-data handling, and processing-time temporal joins.

## Usage

Signature: `PROCTIME()` — no parameters; written as `AS PROCTIME()` in DDL.

No parameters.

Return: TIMESTAMP_LTZ; the timestamp of the moment the current row is processed, non-deterministic.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, PROCTIME() FROM bid;
```

Output: TIMESTAMP_LTZ; the timestamp of the moment each row is processed.

Examples (input → output):

| Input | Output | Notes |
|---|---|---|
| — | 2026-09-11 10:23:41.209 | Regenerated on every row (non-deterministic); the value shown is one sampled draw |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `PROCTIME` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `PROCTIME` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | special-cased in `ExprCodeGenerator` — reads the current row's StreamRecord timestamp; references inside a query body are first rewritten to PROCTIME_MATERIALIZE |

## Velox implementation

The velox repository has no corresponding implementation yet (processing-time attributes are the operators' responsibility).
