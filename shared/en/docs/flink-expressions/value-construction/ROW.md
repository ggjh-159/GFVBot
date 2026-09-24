# ROW

Category: [Value Construction](../index.md#value-construction) | Aliases: —

## Role and scenarios

Row constructor: `ROW(v1, v2, ...)` produces an anonymous composite value whose fields default to the names f0, f1, and so on, renamable with AS. Used to pack heterogeneous values that travel together.

## Usage

Signature: `ROW(v1, v2, ...)` — row constructor syntax.

| Parameter | Type | Description |
|---|---|---|
| v1, v2, ... | Any type | The fields of the row, possibly of different types; field names default to f0, f1, ..., renamable with AS |

Return: ROW<T1, T2, ...>; the field types may differ.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, ROW(1, 'a', bid.auction) FROM bid;
```

Output: ROW<INT, STRING, BIGINT>; each row is `(1, 'a', auction)`.

Example (first 8 rows of the 16-row source, illustrative data; leading columns are input columns, the last column is the result for that row):

| auction | ROW(1, 'a', auction) |
|---|---|
| 3 | (1, a, 3) |
| 19 | (1, a, 19) |
| 8 | (1, a, 8) |
| 1 | (1, a, 1) |
| 14 | (1, a, 14) |
| 7 | (1, a, 7) |
| 11 | (1, a, 11) |
| 20 | (1, a, 20) |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `ROW` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `ROW` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | inlined via the ROW branch of `ExprCodeGenerator` as `GenericRowData` construction |

## Velox implementation

The velox expression kernel handles it as the special form `row_constructor` (`velox/expression/RegisterSpecialForm.cpp`), with no standalone function registration.
