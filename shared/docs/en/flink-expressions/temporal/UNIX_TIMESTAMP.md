# UNIX_TIMESTAMP

Category: [Temporal](../index.md#temporal) | Aliases: —

## Role and scenarios

Converts a time string (with optional format) into epoch seconds according to the session time zone; with no arguments it returns the current epoch seconds. Useful for interoperating with unix-style APIs.

## Usage

Signature: `UNIX_TIMESTAMP([s[, format]])`

| Parameter | Type | Description |
|---|---|---|
| s | STRING | Optional; the time string to convert |
| format | STRING | Optional; the parsing format |

Return: BIGINT; the epoch seconds obtained by reading the text in the session time zone; with no arguments, the current epoch seconds.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, UNIX_TIMESTAMP('2026-09-11 10:00:00') FROM bid;
```

Output: BIGINT; the epoch seconds of '2026-09-11 10:00:00' read in the session time zone — 1789092000 under UTC+8.

Examples (input → output):

| Input | Output | Notes |
|---|---|---|
| UNIX_TIMESTAMP('2026-09-11 10:00:00') | 1789092000 | The text is read in the UTC+8 session time zone |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `UNIX_TIMESTAMP` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `UNIX_TIMESTAMP` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | static methods of `BuiltInMethods` (direct call via `MethodCallGen`) |

## Velox implementation

Velox already provides an implementation: the sparksql suite's `unix_timestamp` (`velox/functions/sparksql/registration/RegisterDatetime.cpp`).
