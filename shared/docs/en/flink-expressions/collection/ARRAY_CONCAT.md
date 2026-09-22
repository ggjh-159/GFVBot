# ARRAY_CONCAT

Category: [Collection](../index.md#collection) | Aliases: —

## Role and scenarios

Concatenates two arrays of the same element type into a single array in argument order, keeping all elements without de-duplication. Used to merge two batches of homogeneous data into one array, for example appending a batch of ids to an existing id list.

## Usage

Signature: `ARRAY_CONCAT(a1, a2)`

| Parameter | Type | Description |
|---|---|---|
| a1 | ARRAY<T> | The array placed first in the concatenation |
| a2 | ARRAY<T> | The array placed second, with the same element type as a1 |

Return: ARRAY<T>; elements are concatenated in argument order, and duplicate elements are kept as-is.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, ARRAY_CONCAT(ARRAY[1,2], ARRAY[3]) FROM bid;
```

Output: ARRAY<INT>; every row is [1, 2, 3].

| Input | Output | Notes |
|---|---|---|
| ARRAY_CONCAT(ARRAY[1,2], ARRAY[3]) | [1, 2, 3] | Concatenates the two arrays in argument order |
| ARRAY_CONCAT(ARRAY[1,2], ARRAY[2]) | [1, 2, 2] | Elements duplicated across the two arrays are not de-duplicated |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | no dedicated operator-table entry; resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | the `ARRAY_CONCAT` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | the `eval()` of `ArrayConcatFunction` (flink-table-runtime, invoked via `BridgingSqlFunctionCallGen`) |

## Velox implementation

Velox already provides the builtin `concat` (`velox/functions/prestosql/registration/ArrayConcatRegistration.cpp`).
