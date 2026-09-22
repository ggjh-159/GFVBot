# REGEXP_REPLACE

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Replaces every substring of s that matches the Java regex with replacement, following java.util.regex semantics, used for digit masking, whitespace normalization, and rewriting log fragments.

## Usage

Signature: `REGEXP_REPLACE(s, regex, replacement)`

| Parameter | Type | Description |
|---|---|---|
| s | STRING | the original string |
| regex | STRING | a Java regular expression |
| replacement | STRING | the replacement text |

Return: STRING; the string after all replacements are done.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, REGEXP_REPLACE(bid.extra, '[0-9]', '#') FROM bid;
```

Output: STRING; every digit in `extra` replaced with '#' (varies with the row data).

Examples (first 8 rows of the 16-row source, illustrative data; leading columns are the input columns, the last column is the result for that row):

| extra | REGEXP_REPLACE(extra, '[0-9]', '#') | Notes |
|---|---|---|
| A3F19C27B4E0 | A#F##C##B#E# | every digit character replaced with '#' |
| 8B2D4F90A1C3 | #B#D#F##A#C# | every digit character replaced with '#' |
| C7E5A0D39F16 | C#E#A#D##F## | every digit character replaced with '#' |
| ZK9M2Q7XVBT5 | ZK#M#Q#XVBT# | every digit character replaced with '#' |
| D4C8B1E6A2F7 | D#C#B#E#A#F# | every digit character replaced with '#' |
| 5F0A9D3C7E8B | #F#A#D#C#E#B | every digit character replaced with '#' |
| ZZYYXXWWVVUU | ZZYYXXWWVVUU | contains no digits; returned unchanged |
| E2B7F5A9C3D0 | E#B#F#A#C#D# | every digit character replaced with '#' |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `REGEXP_REPLACE` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `REGEXP_REPLACE` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generateRegexpReplace` (direct call to `SqlFunctionUtils`'s `regexpReplace`) |

## Velox implementation

Velox already provides the builtin `regexp_replace` (`velox/functions/prestosql/registration/StringFunctionsRegistration.cpp`).
