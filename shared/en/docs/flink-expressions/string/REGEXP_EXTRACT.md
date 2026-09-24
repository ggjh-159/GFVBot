# REGEXP_EXTRACT

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Extracts the idx-th capture group of the first regex match in s, where idx 0 denotes the whole match; returns NULL when there is no match, used to extract fields from semi-structured strings.

## Usage

Signature: `REGEXP_EXTRACT(s, regex[, idx])`

| Parameter | Type | Description |
|---|---|---|
| s | STRING | the string to extract from |
| regex | STRING | a Java regular expression |
| idx | INT | optional, the capture group number, default 1; 0 denotes the whole match |

Return: STRING; the capture group content; yields NULL when there is no match.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, REGEXP_EXTRACT(bid.extra, '([0-9A-F])', 1) FROM bid;
```

Output: STRING; the first captured 0-9A-F character, NULL when there is no match (varies with the row data).

Examples (first 8 rows of the 16-row source, illustrative data; leading columns are the input columns, the last column is the result for that row):

| extra | REGEXP_EXTRACT(extra, '([0-9A-F])', 1) | Notes |
|---|---|---|
| A3F19C27B4E0 | A | the first matching 0-9A-F character |
| 8B2D4F90A1C3 | 8 | the first matching 0-9A-F character |
| C7E5A0D39F16 | C | the first matching 0-9A-F character |
| ZK9M2Q7XVBT5 | 9 | the first matching 0-9A-F character ('Z' and 'K' are not in the set) |
| D4C8B1E6A2F7 | D | the first matching 0-9A-F character |
| 5F0A9D3C7E8B | 5 | the first matching 0-9A-F character |
| ZZYYXXWWVVUU | NULL | no matching character; returns NULL |
| E2B7F5A9C3D0 | E | the first matching 0-9A-F character |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `REGEXP_EXTRACT` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `REGEXP_EXTRACT` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generateRegexpExtract` (direct call to `SqlFunctionUtils`'s `regexpExtract`) |

## Velox implementation

GFV already implements `regexp_extract` on the velox side, registered in `velox/functions/flinksql/Register.cpp` (implemented in `RegexFunctions.h` in the same directory).
