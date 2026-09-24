# ASCII

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Returns the numeric code of the first character of the string s, used to inspect the first character's code value for routing or validation. Returns 0 when s is an empty string.

## Usage

Signature: `ASCII(s)`

| Parameter | Type | Description |
|---|---|---|
| s | STRING | the string whose first-character code is taken |

Return: INT; the numeric code of the first character; an empty string yields 0.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, ASCII(bid.extra) FROM bid;
```

Output: INT; the code of the first character of `extra` (varies with the row data).

Examples (first 8 rows of the 16-row source, illustrative data; leading columns are the input columns, the last column is the result for that row):

| extra | ASCII(extra) | Notes |
|---|---|---|
| A3F19C27B4E0 | 65 | code of the first character 'A' |
| 8B2D4F90A1C3 | 56 | code of the first character '8' |
| C7E5A0D39F16 | 67 | code of the first character 'C' |
| ZK9M2Q7XVBT5 | 90 | code of the first character 'Z' |
| D4C8B1E6A2F7 | 68 | code of the first character 'D' |
| 5F0A9D3C7E8B | 53 | code of the first character '5' |
| ZZYYXXWWVVUU | 90 | code of the first character 'Z' |
| E2B7F5A9C3D0 | 69 | code of the first character 'E' |
| '' (empty string) | 0 | an empty string returns 0 |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `ASCII` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `ASCII` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generateAscii` (inlines `BinaryStringData`'s `byteAt`) |

## Velox implementation

Velox already provides an implementation: the sparksql suite's `ascii` (`velox/functions/sparksql/registration/RegisterString.cpp`).
