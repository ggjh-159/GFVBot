# SHA2

Category: [Hash](../index.md#hash) | Aliases: —

## Role and scenarios

Takes the SHA-2 digest at a specified length — hashLength is 224, 256, 384, or 512; 0 is treated as 256; other lengths are rejected. One spelling covers the entire SHA-2 family.

## Usage

Signature: `SHA2(s, hashLength)`

| Parameter | Type | Description |
|---|---|---|
| s | STRING | The string to digest |
| hashLength | INT | The digest length in bits: 224, 256, 384, or 512; 0 is treated as 256; other lengths are rejected |

Return: STRING; the digest length matches hashLength, rendered as hashLength/4 lowercase hexadecimal characters.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, SHA2(bid.extra, 256) FROM bid;
```

Output: STRING; 64 hexadecimal characters here (hashLength 256), varying with the row data.

Example (first 8 rows of the 16-row source, illustrative data; leading columns are input columns, the last two are the result and its notes for that row):

| extra | SHA2(extra, 256) | Notes |
|---|---|---|
| A3F19C27B4E0 | 1683ce8b4f10d5996920d6b50c283e370b1f2d36bc310f7501707b190ebf4b90 | 256-bit digest, 64 lowercase hexadecimal characters |
| 8B2D4F90A1C3 | c8a6c2f6832233aa17dc4c298bee7d59e1bf364e839a7a2ade38175050edaf6d | 256-bit digest, 64 lowercase hexadecimal characters |
| C7E5A0D39F16 | b7bace464a3ce0a07adde2f4cacacf195a4073cddcc696d737b0f81da6071bf2 | 256-bit digest, 64 lowercase hexadecimal characters |
| ZK9M2Q7XVBT5 | 59b80c6d05771d1c3c76a5a84c9385a97f096a3eae570d2ff7656a8ad6e5f15f | 256-bit digest, 64 lowercase hexadecimal characters |
| D4C8B1E6A2F7 | 66d61b03455e9813b1f24a4e7470f70c18503ea19196d5c7a12c58807129938d | 256-bit digest, 64 lowercase hexadecimal characters |
| 5F0A9D3C7E8B | 409a801df9ae867309af325c178a3b4b01cd61dd9fcce693f780a56be5e4bbfe | 256-bit digest, 64 lowercase hexadecimal characters |
| ZZYYXXWWVVUU | 0e551d54c4146296d8d20bd28227c628489301a07c4a60b2c8f90e980f9661ec | 256-bit digest, 64 lowercase hexadecimal characters |
| E2B7F5A9C3D0 | f914a5388bc952a6a1ee6878c814f50971742cda3bb1e5922deaecc5c7f5e3e3 | 256-bit digest, 64 lowercase hexadecimal characters |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `SHA2` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `SHA2` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generateSha2` (direct call to `SqlFunctionUtils`'s `hash`, algorithm selected by hashLength) |

## Velox implementation

Velox already provides an implementation: the sparksql suite's `sha2` (`velox/functions/sparksql/registration/RegisterBinary.cpp`).
