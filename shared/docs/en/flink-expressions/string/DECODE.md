# DECODE

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Decodes the byte string bytes into a string under the specified character set charset; it is the inverse of ENCODE, used to restore byte data that was transported in encoded form.

## Usage

Signature: `DECODE(bytes, charset)`

| Parameter | Type | Description |
|---|---|---|
| bytes | VARBINARY | the byte string to decode |
| charset | STRING | character set name, e.g. 'utf-8' |

Return: STRING; the text obtained by decoding under charset.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, DECODE(ENCODE(bid.extra, 'utf-8'), 'utf-8') FROM bid;
```

Output: STRING; restored to `extra` itself on every row.

Examples (first 8 rows of the 16-row source, illustrative data; leading columns are the input columns, the last column is the result for that row):

| extra | DECODE(ENCODE(extra, 'utf-8'), 'utf-8') | Notes |
|---|---|---|
| A3F19C27B4E0 | A3F19C27B4E0 | restored to the original string after the encode-decode round trip |
| 8B2D4F90A1C3 | 8B2D4F90A1C3 | restored to the original string after the encode-decode round trip |
| C7E5A0D39F16 | C7E5A0D39F16 | restored to the original string after the encode-decode round trip |
| ZK9M2Q7XVBT5 | ZK9M2Q7XVBT5 | restored to the original string after the encode-decode round trip |
| D4C8B1E6A2F7 | D4C8B1E6A2F7 | restored to the original string after the encode-decode round trip |
| 5F0A9D3C7E8B | 5F0A9D3C7E8B | restored to the original string after the encode-decode round trip |
| ZZYYXXWWVVUU | ZZYYXXWWVVUU | restored to the original string after the encode-decode round trip |
| E2B7F5A9C3D0 | E2B7F5A9C3D0 | restored to the original string after the encode-decode round trip |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `DECODE` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `DECODE` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generateDecode` (generated via `MethodCallGen`) |

## Velox implementation

Velox already provides the builtin `from_utf8` (`velox/functions/prestosql/registration/StringFunctionsRegistration.cpp`) (covers the utf-8 charset only).
