# COALESCE

Category: [Conditional](../index.md#conditional) | Aliases: —

## Role and scenarios

Returns the first non-NULL argument; the result is NULL only when every argument is NULL; all arguments must unify to a single type. The fallback chain for optional columns.

## Usage

Signature: `COALESCE(v1, v2, ...)`

| Parameter | Type | Description |
|---|---|---|
| v1, v2, ... | Unifiable type | Two or more arguments, examined left to right |

Return: the common type of the arguments; the first non-NULL argument, NULL only when every argument is NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, COALESCE(CAST(NULL AS STRING), bid.extra) FROM bid;
```

Output: STRING; that is, `extra` itself — the first argument is NULL, so the second is taken.

Example (first 8 rows of the 16-row source, illustrative data, with a final NULL-boundary row appended; leading columns are inputs, the last two are each row's result and notes):

| extra | COALESCE(NULL, extra) | Notes |
|---|---|---|
| A3F19C27B4E0 | A3F19C27B4E0 | First argument NULL, so extra is taken |
| 8B2D4F90A1C3 | 8B2D4F90A1C3 | First argument NULL, so extra is taken |
| C7E5A0D39F16 | C7E5A0D39F16 | First argument NULL, so extra is taken |
| ZK9M2Q7XVBT5 | ZK9M2Q7XVBT5 | First argument NULL, so extra is taken |
| D4C8B1E6A2F7 | D4C8B1E6A2F7 | First argument NULL, so extra is taken |
| 5F0A9D3C7E8B | 5F0A9D3C7E8B | First argument NULL, so extra is taken |
| ZZYYXXWWVVUU | ZZYYXXWWVVUU | First argument NULL, so extra is taken |
| E2B7F5A9C3D0 | E2B7F5A9C3D0 | First argument NULL, so extra is taken |
| NULL | NULL | NULL only when every argument is NULL |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | No dedicated operator-table entry; the `BuiltInFunctionDefinitions` entry is resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | The `COALESCE` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | The eval() of scalar/`CoalesceFunction` in flink-table-runtime (invoked via `BridgingSqlFunctionCallGen`) |

## Velox implementation

The velox expression kernel handles it as the special form `coalesce` (`velox/expression/RegisterSpecialForm.cpp`), with no standalone function registration.
