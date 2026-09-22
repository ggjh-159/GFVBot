# ARRAY_DISTINCT

Category: [Collection](../index.md#collection) | Aliases: —

## Role and scenarios

Removes duplicate elements from an array; each unique element is kept in order of first occurrence. Used to de-duplicate tag lists and id lists.

## Usage

Signature: `ARRAY_DISTINCT(arr)`

| Parameter | Type | Description |
|---|---|---|
| arr | ARRAY<T> | The array to de-duplicate |

Return: ARRAY<T>; only the first occurrence of each duplicate element is kept.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, ARRAY_DISTINCT(ARRAY[1,2,2,3]) FROM bid;
```

Output: ARRAY<INT>; every row is [1, 2, 3].

| Input | Output | Notes |
|---|---|---|
| ARRAY_DISTINCT(ARRAY[1,2,2,3]) | [1, 2, 3] | The duplicated 2 is kept only once |
| ARRAY_DISTINCT(ARRAY[2,1,2]) | [2, 1] | Kept in order of first occurrence |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | no dedicated operator-table entry; resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | the `ARRAY_DISTINCT` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | the `eval()` of `ArrayDistinctFunction` (flink-table-runtime, invoked via `BridgingSqlFunctionCallGen`) |

## Velox implementation

Velox already provides the builtin `array_distinct` (`velox/functions/prestosql/registration/ArrayFunctionsRegistration.cpp`).
