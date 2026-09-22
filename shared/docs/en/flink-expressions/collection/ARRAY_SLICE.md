# ARRAY_SLICE

Category: [Collection](../index.md#collection) | Aliases: —

## Role and scenarios

Returns the contiguous sub-array of an array from start to end (both endpoints inclusive), where start and end are 1-based indices. Used for paginated extraction and head/tail trimming.

## Usage

Signature: `ARRAY_SLICE(arr, start[, end])`

| Parameter | Type | Description |
|---|---|---|
| arr | ARRAY<T> | The array to slice |
| start | INT | The starting index, 1-based, inclusive |
| end | INT | Optional; the ending index, 1-based, inclusive |

Return: ARRAY<T>; the slice range is a 1-based closed interval.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, ARRAY_SLICE(ARRAY[1,2,3,4], 2, 3) FROM bid;
```

Output: ARRAY<INT>; every row is [2, 3].

| Input | Output | Notes |
|---|---|---|
| ARRAY_SLICE(ARRAY[1,2,3,4], 2, 3) | [2, 3] | 1-based inclusive: takes the 2nd and 3rd elements |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | no dedicated operator-table entry; resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | the `ARRAY_SLICE` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | the `eval()` of `ArraySliceFunction` (flink-table-runtime, invoked via `BridgingSqlFunctionCallGen`) |

## Velox implementation

The velox repository has no corresponding implementation yet.
