# REPLACE

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Replaces every occurrence of search in s with replacement, matching literally rather than as a regex, so no escaping is required.

## Usage

Signature: `REPLACE(s, search, replacement)`

| Parameter | Type | Description |
|---|---|---|
| s | STRING | the original string |
| search | STRING | the literal substring to replace |
| replacement | STRING | the replacement text |

Return: STRING; the string after all replacements are done.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, REPLACE(bid.extra, 'A', 'a') FROM bid;
```

Output: STRING; every 'A' in `extra` changed to 'a' (varies with the row data).

Examples (first 8 rows of the 16-row source, illustrative data; leading columns are the input columns, the last column is the result for that row):

| extra | REPLACE(extra, 'A', 'a') | Notes |
|---|---|---|
| A3F19C27B4E0 | a3F19C27B4E0 | every 'A' replaced with 'a' |
| 8B2D4F90A1C3 | 8B2D4F90a1C3 | every 'A' replaced with 'a' |
| C7E5A0D39F16 | C7E5a0D39F16 | every 'A' replaced with 'a' |
| ZK9M2Q7XVBT5 | ZK9M2Q7XVBT5 | the string contains no 'A'; returned unchanged |
| D4C8B1E6A2F7 | D4C8B1E6a2F7 | every 'A' replaced with 'a' |
| 5F0A9D3C7E8B | 5F0a9D3C7E8B | every 'A' replaced with 'a' |
| ZZYYXXWWVVUU | ZZYYXXWWVVUU | the string contains no 'A'; returned unchanged |
| E2B7F5A9C3D0 | E2B7F5a9C3D0 | every 'A' replaced with 'a' |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `REPLACE` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `REPLACE` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generateReplace` (direct call to `SqlFunctionUtils`'s `replace`) |

## Velox implementation

Velox already provides the builtin `replace` (`velox/functions/prestosql/registration/StringFunctionsRegistration.cpp`).
