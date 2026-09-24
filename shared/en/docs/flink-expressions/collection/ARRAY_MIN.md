# ARRAY_MIN

Category: [Collection](../index.md#collection) | Aliases: —

## Role and scenarios

Returns the minimum element of an array; NULL elements are skipped, and a NULL array yields NULL. Used to extract the smallest value from each row's candidates.

## Usage

Signature: `ARRAY_MIN(arr)`

| Parameter | Type | Description |
|---|---|---|
| arr | ARRAY<T> | The array to take the minimum of |

Return: T (the element type); NULL elements do not take part in the comparison.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, ARRAY_MIN(ARRAY[4,5,3]) FROM bid;
```

Output: INT; every row is 3.

| Input | Output | Notes |
|---|---|---|
| ARRAY_MIN(ARRAY[4,5,3]) | 3 | The minimum element |
| ARRAY_MIN(ARRAY[4,NULL,3]) | 3 | NULL elements are skipped |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | no dedicated operator-table entry; resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | the `ARRAY_MIN` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | the `eval()` of `ArrayMinFunction` (flink-table-runtime, invoked via `BridgingSqlFunctionCallGen`) |

## Velox implementation

Velox already provides the builtin `array_min` (`velox/functions/prestosql/registration/ArrayFunctionsRegistration.cpp`).
