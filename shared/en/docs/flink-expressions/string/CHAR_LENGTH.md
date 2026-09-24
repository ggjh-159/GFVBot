# CHAR_LENGTH

Category: [String](../index.md#string) | Aliases: `CHARACTER_LENGTH`

## Role and scenarios

Counts the number of characters contained in the string s (in characters, not bytes), used for length validation, truncation logic, and width checks. Returns 0 for an empty string.

## Usage

Signature: `CHAR_LENGTH(s)`

| Parameter | Type | Description |
|---|---|---|
| s | STRING/CHAR | the string whose length is counted |

Return: INT; the number of characters; an empty string yields 0.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, CHAR_LENGTH(bid.extra) FROM bid;
```

Output: INT; 12 on every row (`extra` is generated with length 12).

Examples (first 8 rows of the 16-row source, illustrative data; leading columns are the input columns, the last column is the result for that row):

| extra | CHAR_LENGTH(extra) | Notes |
|---|---|---|
| A3F19C27B4E0 | 12 | 12 characters |
| 8B2D4F90A1C3 | 12 | 12 characters |
| C7E5A0D39F16 | 12 | 12 characters |
| ZK9M2Q7XVBT5 | 12 | 12 characters |
| D4C8B1E6A2F7 | 12 | 12 characters |
| 5F0A9D3C7E8B | 12 | 12 characters |
| ZZYYXXWWVVUU | 12 | 12 characters |
| E2B7F5A9C3D0 | 12 | 12 characters |
| '' (empty string) | 0 | an empty string returns 0 |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `CHAR_LENGTH` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `CHAR_LENGTH` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generateCharLength` (inlines `BinaryStringData`'s `numChars`) |

## Velox implementation

Velox already provides the builtin `length` (`velox/functions/prestosql/registration/StringFunctionsRegistration.cpp`) (counts characters for varchar).
