# HEX

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Returns the hexadecimal text of the input: a numeric input is rendered as its hexadecimal digits, while a string input is rendered as the hexadecimal of each of its bytes (two hexadecimal characters per byte). It is used for compact byte-level views and join keys.

## Usage

Signature: `HEX(x)`

| Parameter | Type | Description |
|---|---|---|
| x | Numeric or STRING | A numeric input is rendered by its value; a string input is rendered by its bytes |

Return: STRING; hexadecimal text.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, HEX(bid.extra) FROM bid;
```

Output: STRING; the 24 hexadecimal characters of each row's `extra` bytes.

Example (first 8 of the 16 source rows, illustrative data; leading columns are input columns, the last column is the result for that row):

| extra | HEX(extra) | Notes |
|---|---|---|
| A3F19C27B4E0 | 413346313943323742344530 | The 12 ASCII characters each expand into two hexadecimal characters, 24 in total |
| 8B2D4F90A1C3 | 384232443446393041314333 | '8'→38, 'B'→42, character by character |
| C7E5A0D39F16 | 433745354130443339463136 | Byte-by-byte hexadecimal encoding |
| ZK9M2Q7XVBT5 | 5A4B394D3251375856425435 | 'Z'→5A, 'K'→4B |
| D4C8B1E6A2F7 | 443443384231453641324637 | Byte-by-byte hexadecimal encoding |
| 5F0A9D3C7E8B | 354630413944334337453842 | '5'→35, 'F'→46 |
| ZZYYXXWWVVUU | 5A5A59595858575756565555 | Repeated characters expand one by one |
| E2B7F5A9C3D0 | 453242374635413943334430 | Byte-by-byte hexadecimal encoding |
| HEX(255) | FF | Numeric input form: rendered as its hexadecimal digits |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `HEX` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `HEX` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `MethodCallGen` directly invokes the `HEX_STRING`/`HEX_LONG` methods of `BuiltInMethods` |

## Velox implementation

Velox already provides an implementation: the sparksql suite's `hex` (`velox/functions/sparksql/registration/RegisterMath.cpp`).
