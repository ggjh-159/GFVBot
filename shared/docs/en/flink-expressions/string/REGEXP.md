# REGEXP

Category: [String](../index.md#string) | Aliases: `RLIKE`

## Role and scenarios

Tests whether pattern matches the whole of s under Java regex semantics, returning a boolean result. It must be invoked in function form `REGEXP(s, pattern)` — the infix spelling `a REGEXP b` is rejected by the Flink 1.19 parser.

## Usage

Signature: `REGEXP(s, pattern)`

| Parameter | Type | Description |
|---|---|---|
| s | STRING | the string to match |
| pattern | STRING | a Java regular expression |

Return: BOOLEAN; whether pattern matches the whole of s.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, REGEXP(bid.extra, '^[0-9A-F]+$') FROM bid;
```

Output: BOOLEAN; true when `extra` consists only of the characters 0-9A-F (varies with the row data).

Examples (first 8 rows of the 16-row source, illustrative data; leading columns are the input columns, the last column is the result for that row):

| extra | REGEXP(extra, '^[0-9A-F]+$') | Notes |
|---|---|---|
| A3F19C27B4E0 | TRUE | all characters fall inside the 0-9A-F set |
| 8B2D4F90A1C3 | TRUE | all characters fall inside the 0-9A-F set |
| C7E5A0D39F16 | TRUE | all characters fall inside the 0-9A-F set |
| ZK9M2Q7XVBT5 | FALSE | contains characters outside the set such as Z and K |
| D4C8B1E6A2F7 | TRUE | all characters fall inside the 0-9A-F set |
| 5F0A9D3C7E8B | TRUE | all characters fall inside the 0-9A-F set |
| ZZYYXXWWVVUU | FALSE | contains characters outside the set such as Z and Y |
| E2B7F5A9C3D0 | TRUE | all characters fall inside the 0-9A-F set |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `REGEXP` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `REGEXP` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generateRegExp` (direct call to `SqlFunctionUtils`'s `regExp`) |

## Velox implementation

Velox already provides the builtin `regexp_like` (`velox/functions/prestosql/registration/StringFunctionsRegistration.cpp`) (the velox version does partial matching while Flink requires a full-string match; the sparksql suite registers `rlike`).
