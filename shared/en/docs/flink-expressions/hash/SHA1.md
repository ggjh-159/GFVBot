# SHA1

Category: [Hash](../index.md#hash) | Aliases: —

## Role and scenarios

The 160-bit SHA-1 digest, as 40 lowercase hexadecimal characters. For traditional fingerprinting — use the SHA-2 family for security-related scenarios instead.

## Usage

Signature: `SHA1(s)`

| Parameter | Type | Description |
|---|---|---|
| s | STRING | The string to digest |

Return: STRING; 40 lowercase hexadecimal characters.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, SHA1(bid.extra) FROM bid;
```

Output: STRING; 40 hexadecimal characters per row (varying with the row data).

Example (first 8 rows of the 16-row source, illustrative data; leading columns are input columns, the last two are the result and its notes for that row):

| extra | SHA1(extra) | Notes |
|---|---|---|
| A3F19C27B4E0 | 44efb9590ae04716b158b17ebdaf9e6bfa5c5dab | 160-bit digest, 40 lowercase hexadecimal characters |
| 8B2D4F90A1C3 | 3fde48eac4ceff69c20a7c0daa0467e1eba4ad1f | 160-bit digest, 40 lowercase hexadecimal characters |
| C7E5A0D39F16 | ae380e5be7cdd061963e6791bfa6968732657283 | 160-bit digest, 40 lowercase hexadecimal characters |
| ZK9M2Q7XVBT5 | c725c42b953ede1222cf7090f2f8bf1676e08fe4 | 160-bit digest, 40 lowercase hexadecimal characters |
| D4C8B1E6A2F7 | 12e227e4a5a9248aa8a94cbc89efa07e7f2e1ab2 | 160-bit digest, 40 lowercase hexadecimal characters |
| 5F0A9D3C7E8B | 7ca21ce9fbfd9c1b6e46f245b1f3541b8aa66180 | 160-bit digest, 40 lowercase hexadecimal characters |
| ZZYYXXWWVVUU | 503c53179981a96e0fa7a9c21bb00c9169fdea35 | 160-bit digest, 40 lowercase hexadecimal characters |
| E2B7F5A9C3D0 | 27d75fb52e892e24ee936a61ce4fee4bf5e17491 | 160-bit digest, 40 lowercase hexadecimal characters |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `SHA1` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `SHA1` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generateSha1` (direct call to `SqlFunctionUtils`'s `hash`, algorithm name inlined) |

## Velox implementation

Velox already provides the builtin `sha1` (`velox/functions/prestosql/registration/BinaryFunctionsRegistration.cpp`).
