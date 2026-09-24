# RIGHT

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Returns the last n characters of the string s, used to extract suffixes such as file extensions and trailing markers.

## Usage

Signature: `RIGHT(s, n)`

| Parameter | Type | Description |
|---|---|---|
| s | STRING | the string to extract from |
| n | INT | the number of characters to take |

Return: STRING; the last n characters of s.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, RIGHT(bid.extra, 4) FROM bid;
```

Output: STRING; the last 4 characters of `extra` on every row.

Examples (first 8 rows of the 16-row source, illustrative data; leading columns are the input columns, the last column is the result for that row):

| extra | RIGHT(extra, 4) | Notes |
|---|---|---|
| A3F19C27B4E0 | B4E0 | the last 4 characters are taken |
| 8B2D4F90A1C3 | A1C3 | the last 4 characters are taken |
| C7E5A0D39F16 | 9F16 | the last 4 characters are taken |
| ZK9M2Q7XVBT5 | VBT5 | the last 4 characters are taken |
| D4C8B1E6A2F7 | A2F7 | the last 4 characters are taken |
| 5F0A9D3C7E8B | 7E8B | the last 4 characters are taken |
| ZZYYXXWWVVUU | VVUU | the last 4 characters are taken |
| E2B7F5A9C3D0 | C3D0 | the last 4 characters are taken |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `RIGHT` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `RIGHT` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generateRight` (inline substring extraction) |

## Velox implementation

The velox repository has no corresponding implementation yet.
