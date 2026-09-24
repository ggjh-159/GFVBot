# MAP_ENTRIES

Category: [Collection](../index.md#collection) | Aliases: —

## Role and scenarios

Expands a map into an array of ROW(key, value) pairs, with each key-value pair becoming one element of the result array. Used to adapt a map to row-oriented APIs.

## Usage

Signature: `MAP_ENTRIES(m)`

| Parameter | Type | Description |
|---|---|---|
| m | MAP<K, V> | The map to expand |

Return: ARRAY<ROW<K, V>>; each key-value pair expands into one ROW(key, value).

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, MAP_ENTRIES(MAP['k1', 1]) FROM bid;
```

Output: ARRAY<ROW<STRING, INT>>; each call yields one row (k1, 1).

| Input | Output | Notes |
|---|---|---|
| MAP_ENTRIES(MAP['k1', 1]) | [(k1, 1)] | The key-value pair (k1, 1) expands into one ROW |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | no dedicated operator-table entry; resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | the `MAP_ENTRIES` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | the `eval()` of `MapEntriesFunction` (flink-table-runtime, invoked via `BridgingSqlFunctionCallGen`) |

## Velox implementation

Velox already provides the builtin `map_entries` (`velox/functions/prestosql/registration/MapFunctionsRegistration.cpp`).
