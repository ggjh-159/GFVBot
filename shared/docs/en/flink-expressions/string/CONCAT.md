# CONCAT

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Concatenates two or more string arguments from left to right into one string, used to assemble display strings and composite keys. Returns NULL overall when any argument is NULL.

## Usage

Signature: `CONCAT(s1, s2, ...)`

| Parameter | Type | Description |
|---|---|---|
| s1, s2, ... | STRING | the strings to concatenate, two or more |

Return: STRING; the arguments concatenated in order; yields NULL when any argument is NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, CONCAT(bid.extra, '-suffix') FROM bid;
```

Output: STRING; `extra` plus the literal '-suffix' — 19 characters on every row.

Examples (first 8 rows of the 16-row source, illustrative data; leading columns are the input columns, the last column is the result for that row):

| extra | CONCAT(extra, '-suffix') | Notes |
|---|---|---|
| A3F19C27B4E0 | A3F19C27B4E0-suffix | extra concatenated with the literal, 19 characters in total |
| 8B2D4F90A1C3 | 8B2D4F90A1C3-suffix | extra concatenated with the literal, 19 characters in total |
| C7E5A0D39F16 | C7E5A0D39F16-suffix | extra concatenated with the literal, 19 characters in total |
| ZK9M2Q7XVBT5 | ZK9M2Q7XVBT5-suffix | extra concatenated with the literal, 19 characters in total |
| D4C8B1E6A2F7 | D4C8B1E6A2F7-suffix | extra concatenated with the literal, 19 characters in total |
| 5F0A9D3C7E8B | 5F0A9D3C7E8B-suffix | extra concatenated with the literal, 19 characters in total |
| ZZYYXXWWVVUU | ZZYYXXWWVVUU-suffix | extra concatenated with the literal, 19 characters in total |
| E2B7F5A9C3D0 | E2B7F5A9C3D0-suffix | extra concatenated with the literal, 19 characters in total |
| NULL | NULL | the result is NULL when any argument is NULL |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `CONCAT_FUNCTION` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `CONCAT` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generateConcat` (direct call to `BinaryStringDataUtil`'s `concat`) |

## Velox implementation

Velox already provides the builtin `concat` (`velox/functions/prestosql/registration/StringFunctionsRegistration.cpp`).
