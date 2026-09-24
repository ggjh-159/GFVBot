# MAP_VALUES

Category: [Collection](../index.md#collection) | Aliases: —

## Role and scenarios

Returns an array of all values of a map in the values' iteration order. Used to expand measure values for aggregate functions.

## Usage

Signature: `MAP_VALUES(m)`

| Parameter | Type | Description |
|---|---|---|
| m | MAP<K, V> | The map whose values are taken |

Return: ARRAY<V>; ordered by the values' iteration order.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, MAP_VALUES(MAP['k1', 1, 'k2', 2]) FROM bid;
```

Output: ARRAY<INT>; every row is [1, 2].

| Input | Output | Notes |
|---|---|---|
| MAP_VALUES(MAP['k1', 1, 'k2', 2]) | [1, 2] | Returned in the values' iteration order |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | no dedicated operator-table entry; resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | the `MAP_VALUES` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | the `eval()` of `MapValuesFunction` (flink-table-runtime, invoked via `BridgingSqlFunctionCallGen`) |

## Velox implementation

Velox already provides the builtin `map_values` (`velox/functions/prestosql/registration/MapFunctionsRegistration.cpp`).
