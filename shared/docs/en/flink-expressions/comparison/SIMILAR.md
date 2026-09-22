# SIMILAR

Category: [Comparison](../index.md#comparison) | Aliases: `SIMILAR TO`

## Role and scenarios

Matches via `s SIMILAR TO pattern` against SQL:1999 regexes — whose syntax (character classes, quantifiers built on % and _) differs from both LIKE wildcards and Java regexes. Use it when a pattern needs more expressive power than LIKE provides.

## Usage

Signature: `s SIMILAR TO pattern` — s is the string under test and pattern is an SQL:1999 regex.

Return: BOOLEAN; TRUE when s matches pattern, otherwise FALSE.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.extra SIMILAR TO '%[0-9A-F]%' FROM bid;
```

Output: BOOLEAN; true when `extra` contains at least one character in 0-9A-F (varies with row data).

Example (first 8 rows of the 16-row source, illustrative data, with a final NULL-boundary row appended; leading columns are inputs, the last two are each row's result and notes):

| extra | extra SIMILAR TO '%[0-9A-F]%' | Notes |
|---|---|---|
| A3F19C27B4E0 | TRUE | Contains a character in the `[0-9A-F]` character class |
| 8B2D4F90A1C3 | TRUE | Contains digit characters |
| C7E5A0D39F16 | TRUE | Contains digit characters |
| ZK9M2Q7XVBT5 | TRUE | Contains the digits 9, 2, 7, 5 |
| D4C8B1E6A2F7 | TRUE | Contains digit characters |
| 5F0A9D3C7E8B | TRUE | Contains digit characters |
| ZZYYXXWWVVUU | FALSE | Contains no character in 0-9A-F |
| E2B7F5A9C3D0 | TRUE | Contains digit characters |
| NULL | UNKNOWN | Either side NULL yields UNKNOWN |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | No dedicated operator-table entry; the `BuiltInFunctionDefinitions` entry is resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | The `SIMILAR` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | The `generateSimilarTo` in `StringCallGen` |

## Velox implementation

The velox repository has no corresponding implementation yet.
