# MAP

Category: [Value Construction](../index.md#value-construction) | Aliases: —

## Role and scenarios

Map constructor: `MAP[k1, v1, k2, v2, ...]` writes keys and values alternately, with keys and values each unifying to their own type. Used to build small inline lookup tables.

## Usage

Signature: `MAP[k1, v1, k2, v2, ...]` — constructor syntax with alternating keys and values, not an ordinary function call.

| Parameter | Type | Description |
|---|---|---|
| k1, k2, ... | Any type | Keys, at the odd positions of the alternating sequence; must share one type |
| v1, v2, ... | Any type | Values, at the even positions of the alternating sequence; must share one type |

Return: MAP<K, V>; K and V are the common types of the keys and values.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, MAP['k1', bid.auction, 'k2', bid.bidder] FROM bid;
```

Output: MAP<STRING, BIGINT>; each row is `{k1=auction, k2=bidder}`.

Example (first 8 rows of the 16-row source, illustrative data; leading columns are input columns, the last column is the result for that row):

| auction | bidder | MAP['k1', auction, 'k2', bidder] |
|---|---|---|
| 3 | 15 | {k1=3, k2=15} |
| 19 | 7 | {k1=19, k2=7} |
| 8 | 8 | {k1=8, k2=8} |
| 1 | 42 | {k1=1, k2=42} |
| 14 | 23 | {k1=14, k2=23} |
| 7 | 2 | {k1=7, k2=2} |
| 11 | 11 | {k1=11, k2=11} |
| 20 | 36 | {k1=20, k2=36} |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | no dedicated operator-table entry; resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | the `MAP` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | inlined via the MAP_VALUE_CONSTRUCTOR branch of `ExprCodeGenerator` as `GenericMapData` construction |

## Velox implementation

Velox already provides the builtin `map` (`velox/functions/prestosql/registration/MapFunctionsRegistration.cpp`).
