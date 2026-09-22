# AT

Category: [Collection](../index.md#collection) | Aliases: `[]`, ITEM

## Role and scenarios

Subscript access operator: `arr[i]` reads the i-th element of an array (indices are 1-based), and `map[k]` looks up the value in a map by key. The internal registration name is ITEM — that is the name shown in error messages.

## Usage

Signature: `arr[i]`/`map[k]` — infix operator form, not a function call.

| Parameter | Type | Description |
|---|---|---|
| arr | ARRAY<T> | The array being subscripted |
| i | INT | The array index, 1-based — the first element has index 1 |
| map | MAP<K, V> | The map being looked up by key |
| k | K | The lookup key, of the map's key type |

Return: the array element type or the map value type.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, ARRAY[bid.auction, bid.bidder, 99][3] FROM bid;
```

Output: BIGINT; every row is 99 — the third element of the literal array.

Example (first 8 rows of the 16-row source, illustrative data; leading columns are input columns, the last column is the result for that row):

| auction | bidder | ARRAY[auction, bidder, 99][3] |
|---|---|---|
| 3 | 15 | 99 |
| 19 | 7 | 99 |
| 8 | 8 | 99 |
| 1 | 42 | 99 |
| 14 | 23 | 99 |
| 7 | 2 | 99 |
| 11 | 11 | 99 |
| 20 | 36 | 99 |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | no dedicated operator-table entry; resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | the `AT` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | inlined by the ITEM branch of `ExprCodeGenerator` (array subscript / map lookup) |

## Velox implementation

Velox already provides the builtin `subscript/element_at` (`velox/functions/prestosql/registration/GeneralFunctionsRegistration.cpp`).
