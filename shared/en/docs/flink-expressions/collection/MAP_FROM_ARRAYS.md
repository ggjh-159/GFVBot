# MAP_FROM_ARRAYS

Category: [Collection](../index.md#collection) | Aliases: —

## Role and scenarios

Constructs a MAP from a key array and a value array (keys first); the two arrays must be of equal length, and keys and values are paired by position. This is the inverse direction of MAP_KEYS/MAP_VALUES; used to assemble side-by-side columns into a map.

## Usage

Signature: `MAP_FROM_ARRAYS(keys, values)`

| Parameter | Type | Description |
|---|---|---|
| keys | ARRAY<K> | The key array, first in argument position |
| values | ARRAY<V> | The value array, second in argument position; must be the same length as keys |

Return: MAP<K, V>; keys and values are paired one-to-one by position in the two arrays.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, MAP_FROM_ARRAYS(ARRAY['k'], ARRAY[1]) FROM bid;
```

Output: MAP<STRING, INT>; every row is {k=1}.

| Input | Output | Notes |
|---|---|---|
| MAP_FROM_ARRAYS(ARRAY['k'], ARRAY[1]) | {k=1} | The key array and the value array are paired by position |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | no dedicated operator-table entry; resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | the `MAP_FROM_ARRAYS` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | the `eval()` of `MapFromArraysFunction` (flink-table-runtime, invoked via `BridgingSqlFunctionCallGen`) |

## Velox implementation

Velox already provides an implementation: the sparksql suite's `map_from_arrays` (`velox/functions/sparksql/registration/RegisterMap.cpp`).
