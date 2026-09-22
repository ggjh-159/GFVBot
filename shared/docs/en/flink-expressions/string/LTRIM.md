# LTRIM

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Removes the spaces at the start of the string s (left side only, not the end), used to clean the leading whitespace of left-aligned fixed-width fields.

## Usage

Signature: `LTRIM(s)`

| Parameter | Type | Description |
|---|---|---|
| s | STRING | the string to clean |

Return: STRING; the string with its leading spaces removed.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, LTRIM(CONCAT(' ', bid.extra)) FROM bid;
```

Output: STRING; the one artificially added leading space removed — each row is `extra` itself.

Examples (first 8 rows of the 16-row source, illustrative data; leading columns are the input columns, the last column is the result for that row):

| extra | LTRIM(CONCAT(' ', extra)) | Notes |
|---|---|---|
| A3F19C27B4E0 | A3F19C27B4E0 | after removing the artificially added leading space the result is extra |
| 8B2D4F90A1C3 | 8B2D4F90A1C3 | after removing the artificially added leading space the result is extra |
| C7E5A0D39F16 | C7E5A0D39F16 | after removing the artificially added leading space the result is extra |
| ZK9M2Q7XVBT5 | ZK9M2Q7XVBT5 | after removing the artificially added leading space the result is extra |
| D4C8B1E6A2F7 | D4C8B1E6A2F7 | after removing the artificially added leading space the result is extra |
| 5F0A9D3C7E8B | 5F0A9D3C7E8B | after removing the artificially added leading space the result is extra |
| ZZYYXXWWVVUU | ZZYYXXWWVVUU | after removing the artificially added leading space the result is extra |
| E2B7F5A9C3D0 | E2B7F5A9C3D0 | after removing the artificially added leading space the result is extra |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `LTRIM` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `LTRIM` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generateTrimLeft` (direct call to `BinaryStringDataUtil`'s `trimLeft`) |

## Velox implementation

Velox already provides the builtin `ltrim` (`velox/functions/prestosql/registration/StringFunctionsRegistration.cpp`).
