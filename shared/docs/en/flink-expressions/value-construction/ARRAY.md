# ARRAY

Category: [Value Construction](../index.md#value-construction) | Aliases: —

## Role and scenarios

Array constructor: `ARRAY[v1, v2, ...]` unifies the elements into a common element type and produces an array value. Used to pack multiple columns into a single array value for downstream array functions.

## Usage

Signature: `ARRAY[v1, v2, ...]` — constructor syntax, not an ordinary function call.

| Parameter | Type | Description |
|---|---|---|
| v1, v2, ... | Any type | Array elements; must unify to a common element type |

Return: ARRAY<T>; T is the common type of the elements.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, ARRAY[bid.auction, bid.bidder, 99] FROM bid;
```

Output: ARRAY<BIGINT>; each row is `[auction, bidder, 99]`.

Example (first 8 rows of the 16-row source, illustrative data; leading columns are input columns, the last column is the result for that row):

| auction | bidder | ARRAY[auction, bidder, 99] |
|---|---|---|
| 3 | 15 | [3, 15, 99] |
| 19 | 7 | [19, 7, 99] |
| 8 | 8 | [8, 8, 99] |
| 1 | 42 | [1, 42, 99] |
| 14 | 23 | [14, 23, 99] |
| 7 | 2 | [7, 2, 99] |
| 11 | 11 | [11, 11, 99] |
| 20 | 36 | [20, 36, 99] |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | no dedicated operator-table entry; resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | the `ARRAY` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | inlined via the ARRAY_VALUE_CONSTRUCTOR branch of `ExprCodeGenerator` as `GenericArrayData` construction |

## Velox implementation

Velox already provides an implementation: the sparksql suite's `array` (`velox/functions/sparksql/registration/RegisterArray.cpp`) (the prestosql side also provides `array_constructor`).
