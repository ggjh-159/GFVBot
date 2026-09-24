# ARRAY_POSITION

Category: [Collection](../index.md#collection) | Aliases: —

## Role and scenarios

Returns the 1-based index of the first occurrence of a value in an array; a missing value yields 0, and a NULL array yields NULL. Used to look up the positional rank of a known element.

## Usage

Signature: `ARRAY_POSITION(arr, v)`

| Parameter | Type | Description |
|---|---|---|
| arr | ARRAY<T> | The array to search |
| v | T | The value to locate, of the array element type |

Return: INT; the 1-based index, 0 when the value is absent.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, ARRAY_POSITION(ARRAY[1,2,3], 2) FROM bid;
```

Output: INT; every row is 2.

| Input | Output | Notes |
|---|---|---|
| ARRAY_POSITION(ARRAY[1,2,3], 2) | 2 | 1-based index: 2 is the second element |
| ARRAY_POSITION(ARRAY[1,2,3], 5) | 0 | A missing value yields 0 |
| ARRAY_POSITION(NULL, 2) | NULL | A NULL array yields NULL |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | no dedicated operator-table entry; resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | the `ARRAY_POSITION` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | the `eval()` of `ArrayPositionFunction` (flink-table-runtime, invoked via `BridgingSqlFunctionCallGen`) |

## Velox implementation

Velox already provides the builtin `array_position` (`velox/functions/prestosql/registration/ArrayFunctionsRegistration.cpp`).
