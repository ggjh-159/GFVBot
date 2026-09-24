# CAST

Category: [Type Conversion](../index.md#type-conversion) | Aliases: —

## Role and scenarios

Explicit type conversion; the conversion matrix covers numeric widening and narrowing, string-to-numeric and numeric-to-string, string-to-temporal and temporal-to-string, and relabeling of composite types. Throws a runtime error when the value cannot be converted; use TRY_CAST instead when a silent failure-to-NULL semantics is required.

## Usage

Signature: `CAST(x AS t)`

| Parameter | Type | Description |
|---|---|---|
| x | Any | The value to convert |
| t | SQL type | The target type |

Return: a value of the target type t; throws a runtime error when the conversion is impossible.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, CAST(bid.auction AS VARCHAR) FROM bid;
```

Output: VARCHAR; each row's `auction` in decimal digits (varies with row data).

Examples (first 8 rows of the 16-row source, illustrative data; leading columns are the input columns, the last two are each row's result and notes):

| auction | CAST(auction AS VARCHAR) | Notes |
|---|---|---|
| 3 | 3 | Integer converted to a decimal string |
| 19 | 19 | Integer converted to a decimal string |
| 8 | 8 | Integer converted to a decimal string |
| 1 | 1 | Integer converted to a decimal string |
| 14 | 14 | Integer converted to a decimal string |
| 7 | 7 | Integer converted to a decimal string |
| 11 | 11 | Integer converted to a decimal string |
| 20 | 20 | Integer converted to a decimal string |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `CAST` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `CAST` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | the CAST branch of `ExprCodeGenerator` generates dedicated conversion code per source/target type pair (numeric/string/temporal matrix) |

## Velox implementation

The velox expression kernel handles it as the special form `cast` (`velox/expression/RegisterSpecialForm.cpp`), with no standalone function registration.
