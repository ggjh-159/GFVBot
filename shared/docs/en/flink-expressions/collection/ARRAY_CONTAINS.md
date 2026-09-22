# ARRAY_CONTAINS

Category: [Collection](../index.md#collection) | Aliases: —

## Role and scenarios

Tests whether an array contains a given value: returns TRUE if it does, FALSE if not. Suited to membership tests where the candidate set arrives as column data (rather than literals).

## Usage

Signature: `ARRAY_CONTAINS(arr, v)`

| Parameter | Type | Description |
|---|---|---|
| arr | ARRAY<T> | The array to test |
| v | T | The value to find, of the array element type |

Return: BOOLEAN; TRUE when the value is contained, FALSE when not.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, ARRAY_CONTAINS(ARRAY[1,2,3], 2) FROM bid;
```

Output: BOOLEAN; every row is true.

| Input | Output | Notes |
|---|---|---|
| ARRAY_CONTAINS(ARRAY[1,2,3], 2) | TRUE | 2 is in the array |
| ARRAY_CONTAINS(ARRAY[1,2,3], 9) | FALSE | Returns FALSE when the value is absent |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | no dedicated operator-table entry; resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | the `ARRAY_CONTAINS` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | the `eval()` of `ArrayContainsFunction` (flink-table-runtime, invoked via `BridgingSqlFunctionCallGen`) |

## Velox implementation

Velox already provides the builtin `contains` (`velox/functions/prestosql/registration/ArrayFunctionsRegistration.cpp`) (the sparksql suite registers `array_contains`).
