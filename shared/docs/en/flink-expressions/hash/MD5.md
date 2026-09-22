# MD5

Category: [Hash](../index.md#hash) | Aliases: —

## Role and scenarios

The 128-bit MD5 digest of a string, rendered as 32 lowercase hexadecimal characters. Used for change detection, cache keys, and fingerprinting — its collision resistance is insufficient for security purposes.

## Usage

Signature: `MD5(s)`

| Parameter | Type | Description |
|---|---|---|
| s | STRING | The string to digest |

Return: STRING; 32 lowercase hexadecimal characters.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, MD5(bid.extra) FROM bid;
```

Output: STRING; 32 hexadecimal characters per row (varying with the row data).

Example (first 8 rows of the 16-row source, illustrative data; leading columns are input columns, the last two are the result and its notes for that row):

| extra | MD5(extra) | Notes |
|---|---|---|
| A3F19C27B4E0 | 3391d976e274ac3c8b3987f29f4cfd90 | 128-bit digest, 32 lowercase hexadecimal characters |
| 8B2D4F90A1C3 | d2700e68ec3f4bf6ab516f28083fb04a | 128-bit digest, 32 lowercase hexadecimal characters |
| C7E5A0D39F16 | ffd94a91f55bebe588985be25c3d3edd | 128-bit digest, 32 lowercase hexadecimal characters |
| ZK9M2Q7XVBT5 | acba1453a0ecdcdeb60e6cd1ddd0f70d | 128-bit digest, 32 lowercase hexadecimal characters |
| D4C8B1E6A2F7 | 05c4ad9174cc98f55266ab0883c337b1 | 128-bit digest, 32 lowercase hexadecimal characters |
| 5F0A9D3C7E8B | 7aa3ea2eba7a655fea2c8e2610af726e | 128-bit digest, 32 lowercase hexadecimal characters |
| ZZYYXXWWVVUU | 83fd3f4384f97d588a344e76e0940f03 | 128-bit digest, 32 lowercase hexadecimal characters |
| E2B7F5A9C3D0 | af8edb2fd39e82bc68428cb9d71ef95f | 128-bit digest, 32 lowercase hexadecimal characters |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `MD5` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `MD5` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generateMd5` (direct call to `SqlFunctionUtils`'s `hash`, algorithm name inlined) |

## Velox implementation

Velox already provides the builtin `md5` (`velox/functions/prestosql/registration/BinaryFunctionsRegistration.cpp`).
