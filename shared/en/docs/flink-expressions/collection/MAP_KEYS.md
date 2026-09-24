# MAP_KEYS

Category: [Collection](../index.md#collection) | Aliases: —

## Role and scenarios

Returns an array of all keys of a map in the keys' iteration order. Used to enumerate dimensions and build grouping lists.

## Usage

Signature: `MAP_KEYS(m)`

| Parameter | Type | Description |
|---|---|---|
| m | MAP<K, V> | The map whose keys are taken |

Return: ARRAY<K>; ordered by the keys' iteration order.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, MAP_KEYS(MAP['k1', 1, 'k2', 2]) FROM bid;
```

Output: ARRAY<STRING>; every row is [k1, k2].

| Input | Output | Notes |
|---|---|---|
| MAP_KEYS(MAP['k1', 1, 'k2', 2]) | [k1, k2] | Returned in the keys' iteration order |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | no dedicated operator-table entry; resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | the `MAP_KEYS` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | the `eval()` of `MapKeysFunction` (flink-table-runtime, invoked via `BridgingSqlFunctionCallGen`) |

## Velox implementation

Velox already provides the builtin `map_keys` (`velox/functions/prestosql/registration/MapFunctionsRegistration.cpp`).
