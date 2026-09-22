# ARRAY_REVERSE

Category: [Collection](../index.md#collection) | Aliases: —

## Role and scenarios

Reverses the order of an array's elements; the last element of the original array becomes the first of the result. Used to display append-ordered lists newest-first.

## Usage

Signature: `ARRAY_REVERSE(arr)`

| Parameter | Type | Description |
|---|---|---|
| arr | ARRAY<T> | The array to reverse |

Return: ARRAY<T>; the element order is fully reversed.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, ARRAY_REVERSE(ARRAY[1,2,3]) FROM bid;
```

Output: ARRAY<INT>; every row is [3, 2, 1].

| Input | Output | Notes |
|---|---|---|
| ARRAY_REVERSE(ARRAY[1,2,3]) | [3, 2, 1] | The element order is fully reversed |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | no dedicated operator-table entry; resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | the `ARRAY_REVERSE` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | the `eval()` of `ArrayReverseFunction` (flink-table-runtime, invoked via `BridgingSqlFunctionCallGen`) |

## Velox implementation

The velox repository has no corresponding implementation yet.
