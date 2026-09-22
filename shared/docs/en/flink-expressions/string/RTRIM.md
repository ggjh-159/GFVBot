# RTRIM

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Removes the spaces at the end of the string s (right side only, not the start), used to clean right-padded fields.

## Usage

Signature: `RTRIM(s)`

| Parameter | Type | Description |
|---|---|---|
| s | STRING | the string to clean |

Return: STRING; the string with its trailing spaces removed.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, RTRIM(CONCAT(bid.extra, ' ')) FROM bid;
```

Output: STRING; the one artificially added trailing space removed — each row is `extra` itself.

Examples (first 8 rows of the 16-row source, illustrative data; leading columns are the input columns, the last column is the result for that row):

| extra | RTRIM(CONCAT(extra, ' ')) | Notes |
|---|---|---|
| A3F19C27B4E0 | A3F19C27B4E0 | after removing the artificially added trailing space the result is extra |
| 8B2D4F90A1C3 | 8B2D4F90A1C3 | after removing the artificially added trailing space the result is extra |
| C7E5A0D39F16 | C7E5A0D39F16 | after removing the artificially added trailing space the result is extra |
| ZK9M2Q7XVBT5 | ZK9M2Q7XVBT5 | after removing the artificially added trailing space the result is extra |
| D4C8B1E6A2F7 | D4C8B1E6A2F7 | after removing the artificially added trailing space the result is extra |
| 5F0A9D3C7E8B | 5F0A9D3C7E8B | after removing the artificially added trailing space the result is extra |
| ZZYYXXWWVVUU | ZZYYXXWWVVUU | after removing the artificially added trailing space the result is extra |
| E2B7F5A9C3D0 | E2B7F5A9C3D0 | after removing the artificially added trailing space the result is extra |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `RTRIM` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `RTRIM` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generateTrimRight` (direct call to `BinaryStringDataUtil`'s `trimRight`) |

## Velox implementation

Velox already provides the builtin `rtrim` (`velox/functions/prestosql/registration/StringFunctionsRegistration.cpp`).
