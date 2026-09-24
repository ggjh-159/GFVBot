# TRY_CAST

Category: [Type Conversion](../index.md#type-conversion) | Aliases: —

## Role and scenarios

The same conversion matrix as CAST, but a failed conversion yields NULL instead of throwing an error. Useful for cleansing columns that may contain illegal values, without letting the job be interrupted because individual rows fail to convert.

## Usage

Signature: `TRY_CAST(x AS t)`

| Parameter | Type | Description |
|---|---|---|
| x | Any | The value to convert |
| t | SQL type | The target type |

Return: a value of the target type t; NULL when the conversion is impossible.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, TRY_CAST('bid.extra' AS INT) FROM bid;
```

Output: INT; NULL on every row — the literal 'bid.extra' is not a valid integer.

Examples (input → output):

| Input | Output | Notes |
|---|---|---|
| TRY_CAST('bid.extra' AS INT) | NULL | The literal is not a valid integer; failure yields NULL instead of an error |
| TRY_CAST('123' AS INT) | 123 | A valid integer converts successfully |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `TRY_CAST` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `TRY_CAST` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | same codegen path as CAST, plus a wrapper that yields NULL on failure |

## Velox implementation

The velox expression kernel handles it as the special form `try_cast` (`velox/expression/RegisterSpecialForm.cpp`), with no standalone function registration.
