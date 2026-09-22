# LIKE

Category: [Comparison](../index.md#comparison) | Aliases: —

## Role and scenarios

SQL wildcard matching: `%` matches any character sequence and `_` exactly one character; ESCAPE designates the escape character. Case-sensitive. Used to filter names and ids by shape.

## Usage

Signature: `s LIKE pattern [ESCAPE c]` — s is the string under test, pattern is a pattern string containing wildcards, and ESCAPE c is an optional escape-character clause.

Return: BOOLEAN; TRUE when s matches pattern, otherwise FALSE.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.extra LIKE '%A%' FROM bid;
```

Output: BOOLEAN; true when `extra` contains 'A' (varies with row data).

Example (first 8 rows of the 16-row source, illustrative data, with a final NULL-boundary row appended; leading columns are inputs, the last two are each row's result and notes):

| extra | extra LIKE '%A%' | Notes |
|---|---|---|
| A3F19C27B4E0 | TRUE | Contains 'A'; `%` wildcards any sequence on either side |
| 8B2D4F90A1C3 | TRUE | Contains 'A' |
| C7E5A0D39F16 | TRUE | Contains 'A' |
| ZK9M2Q7XVBT5 | FALSE | Does not contain 'A' |
| D4C8B1E6A2F7 | TRUE | Contains 'A' |
| 5F0A9D3C7E8B | TRUE | Contains 'A' |
| ZZYYXXWWVVUU | FALSE | Does not contain 'A' |
| E2B7F5A9C3D0 | TRUE | Contains 'A' |
| NULL | UNKNOWN | Either side NULL yields UNKNOWN |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | The `LIKE` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | The `LIKE` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen` hands LIKE off to `LikeCallGen` (the compiled pattern is cached as a reusable member of the operator) |

## Velox implementation

Velox already provides the builtin `like` (`velox/functions/prestosql/registration/StringFunctionsRegistration.cpp`).
