# LEFT

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Returns the first n characters of the string s, used for lightweight extraction of prefixes such as area codes and category codes.

## Usage

Signature: `LEFT(s, n)`

| Parameter | Type | Description |
|---|---|---|
| s | STRING | the string to extract from |
| n | INT | the number of characters to take |

Return: STRING; the first n characters of s.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, LEFT(bid.extra, 4) FROM bid;
```

Output: STRING; the first 4 characters of `extra` on every row.

Examples (first 8 rows of the 16-row source, illustrative data; leading columns are the input columns, the last column is the result for that row):

| extra | LEFT(extra, 4) | Notes |
|---|---|---|
| A3F19C27B4E0 | A3F1 | the first 4 characters are taken |
| 8B2D4F90A1C3 | 8B2D | the first 4 characters are taken |
| C7E5A0D39F16 | C7E5 | the first 4 characters are taken |
| ZK9M2Q7XVBT5 | ZK9M | the first 4 characters are taken |
| D4C8B1E6A2F7 | D4C8 | the first 4 characters are taken |
| 5F0A9D3C7E8B | 5F0A | the first 4 characters are taken |
| ZZYYXXWWVVUU | ZZYY | the first 4 characters are taken |
| E2B7F5A9C3D0 | E2B7 | the first 4 characters are taken |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `LEFT` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `LEFT` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generateLeft` (inline substring extraction) |

## Velox implementation

Velox already provides an implementation: the sparksql suite's `left` (`velox/functions/sparksql/registration/RegisterString.cpp`).
