# CARDINALITY

Category: [Collection](../index.md#collection) | Aliases: —

## Role and scenarios

Returns the number of elements in an array or the number of key-value pairs in a map; a NULL input yields NULL. Used for length-guard conditions and loop-by-element-count decisions.

## Usage

Signature: `CARDINALITY(arr_or_map)`

| Parameter | Type | Description |
|---|---|---|
| arr_or_map | ARRAY<T> or MAP<K, V> | The array or map to count |

Return: INT; the number of array elements or map key-value pairs.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, CARDINALITY(ARRAY[bid.auction, bid.bidder]) FROM bid;
```

Output: INT; every row is 2.

Example (first 8 rows of the 16-row source, illustrative data; leading columns are input columns, the last column is the result for that row):

| auction | bidder | CARDINALITY(ARRAY[auction, bidder]) |
|---|---|---|
| 3 | 15 | 2 |
| 19 | 7 | 2 |
| 8 | 8 | 2 |
| 1 | 42 | 2 |
| 14 | 23 | 2 |
| 7 | 2 | 2 |
| 11 | 11 | 2 |
| 20 | 36 | 2 |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `CARDINALITY` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `CARDINALITY` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | inlined via the CARDINALITY branch of `ExprCodeGenerator` (reading the array/map size) |

## Velox implementation

Velox already provides the builtin `cardinality` (`velox/functions/prestosql/registration/GeneralFunctionsRegistration.cpp`).
