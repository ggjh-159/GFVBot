# LOCATE

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Returns the 1-based position of the first occurrence of sub in s, or 0 if it does not occur, used to locate substrings. Semantically identical to POSITION, written `LOCATE(sub, s[, start])`; the optional 1-based start is used to skip a prefix before searching.

## Usage

Signature: `LOCATE(sub, s[, start])`

| Parameter | Type | Description |
|---|---|---|
| sub | STRING | the substring to locate |
| s | STRING | the string searched in |
| start | INT | optional, the search start, 1-based |

Return: INT; the position of the first occurrence, 1-based; yields 0 when there is none.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, LOCATE('A', bid.extra) FROM bid;
```

Output: INT; the index of the first 'A' in `extra`, 0 if there is none (varies with the row data).

Examples (first 8 rows of the 16-row source, illustrative data; leading columns are the input columns, the last column is the result for that row):

| extra | LOCATE('A', extra) | Notes |
|---|---|---|
| A3F19C27B4E0 | 1 | the first 'A' is at character 1 |
| 8B2D4F90A1C3 | 9 | the first 'A' is at character 9 |
| C7E5A0D39F16 | 5 | the first 'A' is at character 5 |
| ZK9M2Q7XVBT5 | 0 | the string contains no 'A'; returns 0 |
| D4C8B1E6A2F7 | 9 | the first 'A' is at character 9 |
| 5F0A9D3C7E8B | 4 | the first 'A' is at character 4 |
| ZZYYXXWWVVUU | 0 | the string contains no 'A'; returns 0 |
| E2B7F5A9C3D0 | 7 | the first 'A' is at character 7 |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `LOCATE` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `LOCATE` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generateLocate` (direct call to `SqlFunctionUtils`) |

## Velox implementation

Velox already provides an implementation: the sparksql suite's `locate` (`velox/functions/sparksql/registration/RegisterString.cpp`).
