# FROM_UNIXTIME

Category: [Temporal](../index.md#temporal) | Aliases: —

## Role and scenarios

Formats epoch seconds (BIGINT) as a time string, with an optional format pattern; the rendered text varies with the session time zone. Useful for rendering epoch columns into human-readable form.

## Usage

Signature: `FROM_UNIXTIME(unixtime[, format])`

| Parameter | Type | Description |
|---|---|---|
| unixtime | BIGINT | Epoch seconds |
| format | STRING | Optional format pattern |

Return: STRING; the time text rendered in the session time zone.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, FROM_UNIXTIME(1760000000) FROM bid;
```

Output: STRING; 1760000000 renders as '2025-10-09 12:26:40' under UTC — the text varies with the session time zone ('2025-10-09 20:26:40' under Asia/Shanghai).

Examples (input → output):

| Input | Output | Notes |
|---|---|---|
| FROM_UNIXTIME(1760000000) | 2025-10-09 12:26:40 | Rendered under the UTC session time zone |
| FROM_UNIXTIME(1760000000) | 2025-10-09 20:26:40 | Rendered under the Asia/Shanghai session time zone |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `FROM_UNIXTIME` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `FROM_UNIXTIME` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | static methods of `BuiltInMethods` (direct call via `MethodCallGen`) |

## Velox implementation

Velox already provides an implementation: the sparksql suite's `from_unixtime` (`velox/functions/sparksql/registration/RegisterDatetime.cpp`) (returns a string, consistent with Flink).
