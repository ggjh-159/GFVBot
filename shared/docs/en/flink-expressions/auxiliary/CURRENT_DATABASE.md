# CURRENT_DATABASE

Category: [Auxiliary](../index.md#auxiliary) | Aliases: —

## Role and scenarios

Returns the current database name of the session as a STRING. It is used for templated SQL and environment-aware routing.

## Usage

Signature: `CURRENT_DATABASE()`

No parameters.

Return: STRING; the session's current database name.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, CURRENT_DATABASE() FROM bid;
```

Output: STRING; 'default_database' on every row.

Example (input → output):

| Input | Output | Notes |
|---|---|---|
| — | default_database | The session's current database when no database has been switched to |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `CURRENT_DATABASE` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `CURRENT_DATABASE` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | the CURRENT_DATABASE branch of `StringCallGen` inlines the query-level database name via `addReusableQueryLevelCurrentDatabase` |

## Velox implementation

The velox repository has no corresponding implementation yet (session metadata, not an evaluation function).
