# POSITION

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Returns the 1-based position of the first occurrence of x in s, 0 when it does not occur, and NULL when either input is NULL, used to locate substrings. Uses the standard SQL form `POSITION(x IN s)`.

## Usage

Signature: `POSITION(x IN s)`

| Parameter | Type | Description |
|---|---|---|
| x | STRING | the substring to locate |
| s | STRING | the string searched in |

Return: INT; the position of the first occurrence, 1-based; yields 0 when there is none; yields NULL when either input is NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, POSITION('A' IN bid.extra) FROM bid;
```

Output: INT; the index of the first 'A' in `extra`, 0 if there is none (varies with the row data).

Examples (first 8 rows of the 16-row source, illustrative data; leading columns are the input columns, the last column is the result for that row):

| extra | POSITION('A' IN extra) | Notes |
|---|---|---|
| A3F19C27B4E0 | 1 | the first 'A' is at character 1 |
| 8B2D4F90A1C3 | 9 | the first 'A' is at character 9 |
| C7E5A0D39F16 | 5 | the first 'A' is at character 5 |
| ZK9M2Q7XVBT5 | 0 | the string contains no 'A'; returns 0 |
| D4C8B1E6A2F7 | 9 | the first 'A' is at character 9 |
| 5F0A9D3C7E8B | 4 | the first 'A' is at character 4 |
| ZZYYXXWWVVUU | 0 | the string contains no 'A'; returns 0 |
| E2B7F5A9C3D0 | 7 | the first 'A' is at character 7 |
| NULL | NULL | returns NULL when either input is NULL |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `POSITION` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `POSITION` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generatePosition` (direct call to `SqlFunctionUtils`'s `position`) |

## Velox implementation

Velox already provides the builtin `strpos` (`velox/functions/prestosql/registration/StringFunctionsRegistration.cpp`).
