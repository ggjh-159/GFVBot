# ENCODE

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Encodes the string s into a byte string under the specified character set charset, used to prepare input for byte-level functions.

## Usage

Signature: `ENCODE(s, charset)`

| Parameter | Type | Description |
|---|---|---|
| s | STRING | the string to encode |
| charset | STRING | character set name, e.g. 'utf-8' |

Return: VARBINARY; the byte string obtained by encoding under charset.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, ENCODE(bid.extra, 'utf-8') FROM bid;
```

Output: VARBINARY; the 12 UTF-8 bytes of `extra` on every row.

Examples (first 8 rows of the 16-row source, illustrative data; leading columns are the input columns, the last column is the result for that row; the output column shows the byte string in hexadecimal):

| extra | ENCODE(extra, 'utf-8') | Notes |
|---|---|---|
| A3F19C27B4E0 | 413346313943323742344530 | UTF-8 bytes of the 12 ASCII characters, one byte each |
| 8B2D4F90A1C3 | 384232443446393041314333 | UTF-8 bytes of the 12 ASCII characters, one byte each |
| C7E5A0D39F16 | 433745354130443339463136 | UTF-8 bytes of the 12 ASCII characters, one byte each |
| ZK9M2Q7XVBT5 | 5A4B394D3251375856425435 | UTF-8 bytes of the 12 ASCII characters, one byte each |
| D4C8B1E6A2F7 | 443443384231453641324637 | UTF-8 bytes of the 12 ASCII characters, one byte each |
| 5F0A9D3C7E8B | 354630413944334337453842 | UTF-8 bytes of the 12 ASCII characters, one byte each |
| ZZYYXXWWVVUU | 5A5A59595858575756565555 | UTF-8 bytes of the 12 ASCII characters, one byte each |
| E2B7F5A9C3D0 | 453242374635413943334430 | UTF-8 bytes of the 12 ASCII characters, one byte each |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `ENCODE` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `ENCODE` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generateEncode` (generated via `MethodCallGen`) |

## Velox implementation

Velox already provides the builtin `to_utf8` (`velox/functions/prestosql/registration/StringFunctionsRegistration.cpp`) (covers the utf-8 charset only).
