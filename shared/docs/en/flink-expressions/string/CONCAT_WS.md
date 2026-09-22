# CONCAT_WS

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Joins the remaining string arguments with the separator sep, used to produce readable lists of the form 'a,b,c'. NULL arguments are skipped without leaving empty slots; NULL is returned only when the separator sep is NULL.

## Usage

Signature: `CONCAT_WS(sep, s1, s2, ...)`

| Parameter | Type | Description |
|---|---|---|
| sep | STRING | the separator used for joining, placed first in the argument list |
| s1, s2, ... | STRING | the strings to join, two or more |

Return: STRING; the non-NULL arguments joined with sep; yields NULL when sep is NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, CONCAT_WS('-', bid.extra, 'x') FROM bid;
```

Output: STRING; `<extra>-x` on every row.

Examples (first 8 rows of the 16-row source, illustrative data; leading columns are the input columns, the last column is the result for that row):

| extra | CONCAT_WS('-', extra, 'x') | Notes |
|---|---|---|
| A3F19C27B4E0 | A3F19C27B4E0-x | extra and 'x' joined with '-' |
| 8B2D4F90A1C3 | 8B2D4F90A1C3-x | extra and 'x' joined with '-' |
| C7E5A0D39F16 | C7E5A0D39F16-x | extra and 'x' joined with '-' |
| ZK9M2Q7XVBT5 | ZK9M2Q7XVBT5-x | extra and 'x' joined with '-' |
| D4C8B1E6A2F7 | D4C8B1E6A2F7-x | extra and 'x' joined with '-' |
| 5F0A9D3C7E8B | 5F0A9D3C7E8B-x | extra and 'x' joined with '-' |
| ZZYYXXWWVVUU | ZZYYXXWWVVUU-x | extra and 'x' joined with '-' |
| E2B7F5A9C3D0 | E2B7F5A9C3D0-x | extra and 'x' joined with '-' |
| NULL | x | the NULL argument is skipped, leaving only the literal 'x' |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `CONCAT_WS` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `CONCAT_WS` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generateConcatWs` (direct call to `BinaryStringDataUtil`'s `concatWs`) |

## Velox implementation

Velox already provides an implementation: the sparksql suite's `concat_ws` (`velox/functions/sparksql/registration/RegisterString.cpp`).
