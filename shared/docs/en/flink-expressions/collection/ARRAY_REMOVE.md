# ARRAY_REMOVE

Category: [Collection](../index.md#collection) | Aliases: —

## Role and scenarios

Removes from an array every element equal to the given value; the remaining elements keep their original order. Used for blacklist filtering on tagged data.

## Usage

Signature: `ARRAY_REMOVE(arr, v)`

| Parameter | Type | Description |
|---|---|---|
| arr | ARRAY<T> | The original array |
| v | T | The value to remove, of the array element type |

Return: ARRAY<T>; every occurrence of the matched value is removed.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, ARRAY_REMOVE(ARRAY[1,2,1], 1) FROM bid;
```

Output: ARRAY<INT>; every row is [2].

| Input | Output | Notes |
|---|---|---|
| ARRAY_REMOVE(ARRAY[1,2,1], 1) | [2] | Both occurrences of 1 are removed |
| ARRAY_REMOVE(ARRAY[1,2], 9) | [1, 2] | The array is returned unchanged when the value is absent |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | no dedicated operator-table entry; resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | the `ARRAY_REMOVE` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | the `eval()` of `ArrayRemoveFunction` (flink-table-runtime, invoked via `BridgingSqlFunctionCallGen`) |

## Velox implementation

Velox already provides the builtin `array_remove` (`velox/functions/prestosql/registration/ArrayFunctionsRegistration.cpp`).
