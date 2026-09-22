# SUBSTRING

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Extracts m characters from s starting at the 1-based position n, running to the end of the string when m is omitted; it is the most commonly used field-slicing expression. Supports the standard form `SUBSTRING(s FROM n [FOR m])` and the function form `SUBSTRING(s, n[, m])`.

## Usage

Signature: `SUBSTRING(s FROM n [FOR m])` or `SUBSTRING(s, n[, m])`

| Parameter | Type | Description |
|---|---|---|
| s | STRING | the string to extract from |
| n | INT | the start position, 1-based |
| m | INT | optional, the number of characters to take; runs to the end of the string when omitted |

Return: STRING; the extracted substring.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, SUBSTRING(bid.extra FROM 2 FOR 5) FROM bid;
```

Output: STRING; characters 2 through 6 of `extra` on every row (5 in total).

Examples (first 8 rows of the 16-row source, illustrative data; leading columns are the input columns, the last column is the result for that row):

| extra | SUBSTRING(extra FROM 2 FOR 5) | Notes |
|---|---|---|
| A3F19C27B4E0 | 3F19C | 5 characters taken starting at character 2 |
| 8B2D4F90A1C3 | B2D4F | 5 characters taken starting at character 2 |
| C7E5A0D39F16 | 7E5A0 | 5 characters taken starting at character 2 |
| ZK9M2Q7XVBT5 | K9M2Q | 5 characters taken starting at character 2 |
| D4C8B1E6A2F7 | 4C8B1 | 5 characters taken starting at character 2 |
| 5F0A9D3C7E8B | F0A9D | 5 characters taken starting at character 2 |
| ZZYYXXWWVVUU | ZYYXX | 5 characters taken starting at character 2 |
| E2B7F5A9C3D0 | 2B7F5 | 5 characters taken starting at character 2 |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `SUBSTRING` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `SUBSTRING` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generateSubString` (direct call to `BinaryStringDataUtil`'s `substringSQL`) |

## Velox implementation

Velox already provides the builtin `substr` (`velox/functions/prestosql/registration/StringFunctionsRegistration.cpp`) (`substring` in sparksql has the same semantics).
