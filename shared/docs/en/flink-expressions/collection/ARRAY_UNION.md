# ARRAY_UNION

Category: [Collection](../index.md#collection) | Aliases: —

## Role and scenarios

Returns the union of two arrays with de-duplication; each element appears at most once in the result. Used to merge tag sets from two sources.

## Usage

Signature: `ARRAY_UNION(a1, a2)`

| Parameter | Type | Description |
|---|---|---|
| a1 | ARRAY<T> | The first array |
| a2 | ARRAY<T> | The second array, with the same element type as a1 |

Return: ARRAY<T>; the union result contains no duplicates.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, ARRAY_UNION(ARRAY[1,2], ARRAY[2,3]) FROM bid;
```

Output: ARRAY<INT>; every row is [1, 2, 3].

| Input | Output | Notes |
|---|---|---|
| ARRAY_UNION(ARRAY[1,2], ARRAY[2,3]) | [1, 2, 3] | The 2 shared by both arrays appears only once in the result |
| ARRAY_UNION(ARRAY[1,1], ARRAY[2]) | [1, 2] | Duplicates within an array are also de-duplicated |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | no dedicated operator-table entry; resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | the `ARRAY_UNION` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | the `eval()` of `ArrayUnionFunction` (flink-table-runtime, invoked via `BridgingSqlFunctionCallGen`) |

## Velox implementation

Velox already provides the builtin `array_union` (`velox/functions/prestosql/registration/ArrayFunctionsRegistration.cpp`).
