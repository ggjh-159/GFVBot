# REVERSE

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Reverses the order of the characters in the string s, used for palindrome checks and byte-level debugging.

## Usage

Signature: `REVERSE(s)`

| Parameter | Type | Description |
|---|---|---|
| s | STRING | the string to reverse |

Return: STRING; the string with its characters in reverse order.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, REVERSE(bid.extra) FROM bid;
```

Output: STRING; `extra` reversed — 12 characters on every row.

Examples (first 8 rows of the 16-row source, illustrative data; leading columns are the input columns, the last column is the result for that row):

| extra | REVERSE(extra) | Notes |
|---|---|---|
| A3F19C27B4E0 | 0E4B72C91F3A | the 12 characters in reverse order |
| 8B2D4F90A1C3 | 3C1A09F4D2B8 | the 12 characters in reverse order |
| C7E5A0D39F16 | 61F93D0A5E7C | the 12 characters in reverse order |
| ZK9M2Q7XVBT5 | 5TBVX7Q2M9KZ | the 12 characters in reverse order |
| D4C8B1E6A2F7 | 7F2A6E1B8C4D | the 12 characters in reverse order |
| 5F0A9D3C7E8B | B8E7C3D9A0F5 | the 12 characters in reverse order |
| ZZYYXXWWVVUU | UUVVWWXXYYZZ | the 12 characters in reverse order |
| E2B7F5A9C3D0 | 0D3C9A5F7B2E | the 12 characters in reverse order |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `REVERSE` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `REVERSE` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generateReverse` (direct call to `BinaryStringDataUtil`'s `reverse`) |

## Velox implementation

Velox already provides the builtin `reverse` (`velox/functions/prestosql/registration/StringFunctionsRegistration.cpp`).
