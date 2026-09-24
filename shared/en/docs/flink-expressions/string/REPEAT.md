# REPEAT

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Returns the string s repeated n times, used to build delimiter strings and expected patterns in tests.

## Usage

Signature: `REPEAT(s, n)`

| Parameter | Type | Description |
|---|---|---|
| s | STRING | the string to repeat |
| n | INT | the number of repetitions |

Return: STRING; the result of repeating s n times.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, REPEAT(bid.extra, 2) FROM bid;
```

Output: STRING; `extra` repeated twice — 24 characters on every row.

Examples (first 8 rows of the 16-row source, illustrative data; leading columns are the input columns, the last column is the result for that row):

| extra | REPEAT(extra, 2) | Notes |
|---|---|---|
| A3F19C27B4E0 | A3F19C27B4E0A3F19C27B4E0 | extra repeated twice, 24 characters in total |
| 8B2D4F90A1C3 | 8B2D4F90A1C38B2D4F90A1C3 | extra repeated twice, 24 characters in total |
| C7E5A0D39F16 | C7E5A0D39F16C7E5A0D39F16 | extra repeated twice, 24 characters in total |
| ZK9M2Q7XVBT5 | ZK9M2Q7XVBT5ZK9M2Q7XVBT5 | extra repeated twice, 24 characters in total |
| D4C8B1E6A2F7 | D4C8B1E6A2F7D4C8B1E6A2F7 | extra repeated twice, 24 characters in total |
| 5F0A9D3C7E8B | 5F0A9D3C7E8B5F0A9D3C7E8B | extra repeated twice, 24 characters in total |
| ZZYYXXWWVVUU | ZZYYXXWWVVUUZZYYXXWWVVUU | extra repeated twice, 24 characters in total |
| E2B7F5A9C3D0 | E2B7F5A9C3D0E2B7F5A9C3D0 | extra repeated twice, 24 characters in total |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `REPEAT` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `REPEAT` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generateRepeat` (direct call to `SqlFunctionUtils`'s `repeat`) |

## Velox implementation

Velox already provides an implementation: the sparksql suite's `repeat` (`velox/functions/sparksql/registration/RegisterString.cpp`).
