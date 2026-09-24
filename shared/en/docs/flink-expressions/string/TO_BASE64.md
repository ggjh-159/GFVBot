# TO_BASE64

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Encodes the string s as base64 text, so that byte content can pass safely through text channels.

## Usage

Signature: `TO_BASE64(s)`

| Parameter | Type | Description |
|---|---|---|
| s | STRING | the string to encode |

Return: STRING; the base64-encoded text.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, TO_BASE64(bid.extra) FROM bid;
```

Output: STRING; the base64 of `extra`'s 12 bytes — 16 characters on every row.

Examples (first 8 rows of the 16-row source, illustrative data; leading columns are the input columns, the last column is the result for that row):

| extra | TO_BASE64(extra) | Notes |
|---|---|---|
| A3F19C27B4E0 | QTNGMTlDMjdCNEUw | 12 bytes encoded as 16 base64 characters |
| 8B2D4F90A1C3 | OEIyRDRGOTBBMUMz | 12 bytes encoded as 16 base64 characters |
| C7E5A0D39F16 | QzdFNUEwRDM5RjE2 | 12 bytes encoded as 16 base64 characters |
| ZK9M2Q7XVBT5 | Wks5TTJRN1hWQlQ1 | 12 bytes encoded as 16 base64 characters |
| D4C8B1E6A2F7 | RDRDOEIxRTZBMkY3 | 12 bytes encoded as 16 base64 characters |
| 5F0A9D3C7E8B | NUYwQTlEM0M3RThC | 12 bytes encoded as 16 base64 characters |
| ZZYYXXWWVVUU | WlpZWVhYV1dWVlVV | 12 bytes encoded as 16 base64 characters |
| E2B7F5A9C3D0 | RTJCN0Y1QTlDM0Qw | 12 bytes encoded as 16 base64 characters |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `TO_BASE64` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `TO_BASE64` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generateToBase64` (direct call to `SqlFunctionUtils`'s `toBase64`) |

## Velox implementation

Velox already provides the builtin `to_base64` (`velox/functions/prestosql/registration/BinaryFunctionsRegistration.cpp`).
