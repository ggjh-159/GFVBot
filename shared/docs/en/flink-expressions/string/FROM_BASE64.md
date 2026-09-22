# FROM_BASE64

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Decodes the base64 text s back into the original string; it is the inverse of TO_BASE64.

## Usage

Signature: `FROM_BASE64(s)`

| Parameter | Type | Description |
|---|---|---|
| s | STRING | base64-encoded text |

Return: STRING; the original string restored by decoding.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, FROM_BASE64(TO_BASE64(bid.extra)) FROM bid;
```

Output: STRING; restored to `extra` itself on every row.

Examples (first 8 rows of the 16-row source, illustrative data; leading columns are the input columns, the last column is the result for that row):

| extra | FROM_BASE64(TO_BASE64(extra)) | Notes |
|---|---|---|
| A3F19C27B4E0 | A3F19C27B4E0 | restored to the original string after the base64 encode-decode round trip |
| 8B2D4F90A1C3 | 8B2D4F90A1C3 | restored to the original string after the base64 encode-decode round trip |
| C7E5A0D39F16 | C7E5A0D39F16 | restored to the original string after the base64 encode-decode round trip |
| ZK9M2Q7XVBT5 | ZK9M2Q7XVBT5 | restored to the original string after the base64 encode-decode round trip |
| D4C8B1E6A2F7 | D4C8B1E6A2F7 | restored to the original string after the base64 encode-decode round trip |
| 5F0A9D3C7E8B | 5F0A9D3C7E8B | restored to the original string after the base64 encode-decode round trip |
| ZZYYXXWWVVUU | ZZYYXXWWVVUU | restored to the original string after the base64 encode-decode round trip |
| E2B7F5A9C3D0 | E2B7F5A9C3D0 | restored to the original string after the base64 encode-decode round trip |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `FROM_BASE64` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `FROM_BASE64` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generateFromBase64` (direct call to `SqlFunctionUtils`'s `fromBase64`) |

## Velox implementation

Velox already provides the builtin `from_base64` (`velox/functions/prestosql/registration/BinaryFunctionsRegistration.cpp`).
