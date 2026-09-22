# TO_TIMESTAMP_LTZ

Category: [Temporal](../index.md#temporal) | Aliases: —

## Role and scenarios

Converts a raw epoch value into a TIMESTAMP WITH LOCAL TIME ZONE at the given precision — 0 seconds, 3 milliseconds, 6 microseconds, 9 nanoseconds — rendered according to the session time zone. Useful for converting numeric epoch columns.

## Usage

Signature: `TO_TIMESTAMP_LTZ(numeric, precision)`

| Parameter | Type | Description |
|---|---|---|
| numeric | BIGINT | Raw epoch value |
| precision | INT | Precision of the epoch value: 0 seconds, 3 milliseconds, 6 microseconds, 9 nanoseconds |

Return: TIMESTAMP_LTZ; the timestamp constructed from the epoch value, rendered in the session time zone.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, TO_TIMESTAMP_LTZ(1760000000, 3) FROM bid;
```

Output: TIMESTAMP_LTZ; i.e. 2025-10-09T12:26:40Z (epoch milliseconds), rendered in the session time zone.

Examples (input → output):

| Input | Output | Notes |
|---|---|---|
| TO_TIMESTAMP_LTZ(1760000000, 3) | 2025-10-09 12:26:40.000 | precision=3 interprets the value as epoch milliseconds; rendered in the UTC session time zone |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `TO_TIMESTAMP_LTZ` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `TO_TIMESTAMP_LTZ` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | static methods of `BuiltInMethods` (direct call via `MethodCallGen`) |

## Velox implementation

The velox repository has no corresponding implementation yet.
