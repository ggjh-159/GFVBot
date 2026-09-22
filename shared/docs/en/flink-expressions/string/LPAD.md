# LPAD

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Pads s on the left with pad to exactly len characters; when s is longer than len characters the result is truncated to len characters. Used to format fixed-width codes and display columns.

## Usage

Signature: `LPAD(s, len, pad)`

| Parameter | Type | Description |
|---|---|---|
| s | STRING | the original string |
| len | INT | the result width |
| pad | STRING | the string used for padding |

Return: STRING; a result of width len; over-long input is truncated to len.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, LPAD(bid.extra, 15, '*') FROM bid;
```

Output: STRING; width 15 — three '*' prefixed to `extra` on every row.

Examples (first 8 rows of the 16-row source, illustrative data; leading columns are the input columns, the last column is the result for that row):

| extra | LPAD(extra, 15, '*') | Notes |
|---|---|---|
| A3F19C27B4E0 | ***A3F19C27B4E0 | three '*' padded on the left up to width 15 |
| 8B2D4F90A1C3 | ***8B2D4F90A1C3 | three '*' padded on the left up to width 15 |
| C7E5A0D39F16 | ***C7E5A0D39F16 | three '*' padded on the left up to width 15 |
| ZK9M2Q7XVBT5 | ***ZK9M2Q7XVBT5 | three '*' padded on the left up to width 15 |
| D4C8B1E6A2F7 | ***D4C8B1E6A2F7 | three '*' padded on the left up to width 15 |
| 5F0A9D3C7E8B | ***5F0A9D3C7E8B | three '*' padded on the left up to width 15 |
| ZZYYXXWWVVUU | ***ZZYYXXWWVVUU | three '*' padded on the left up to width 15 |
| E2B7F5A9C3D0 | ***E2B7F5A9C3D0 | three '*' padded on the left up to width 15 |
| abcdefghijklmnopqrst (illustrative, 20 characters) | abcdefghijklmno | when the input exceeds len it is truncated to the first len=15 characters |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `LPAD` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `LPAD` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generateLpad` (direct call to `SqlFunctionUtils`'s `lpad`) |

## Velox implementation

Velox already provides the builtin `lpad` (`velox/functions/prestosql/registration/StringFunctionsRegistration.cpp`).
