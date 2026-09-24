# LOWER

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Converts the string s entirely to lowercase, used to normalize the case of identifiers and keys before a JOIN or deduplication. Returns NULL when s is NULL.

## Usage

Signature: `LOWER(s)`

| Parameter | Type | Description |
|---|---|---|
| s | STRING/CHAR | the string to convert |

Return: STRING; the fully lowercased result; a NULL input yields NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, LOWER(bid.extra) FROM bid;
```

Output: STRING; the 12 characters of `extra` lowercased on every row (varies with the row data).

Examples (first 8 rows of the 16-row source, illustrative data; leading columns are the input columns, the last column is the result for that row):

| extra | LOWER(extra) | Notes |
|---|---|---|
| A3F19C27B4E0 | a3f19c27b4e0 | all letters converted to lowercase |
| 8B2D4F90A1C3 | 8b2d4f90a1c3 | all letters converted to lowercase |
| C7E5A0D39F16 | c7e5a0d39f16 | all letters converted to lowercase |
| ZK9M2Q7XVBT5 | zk9m2q7xvbt5 | all letters converted to lowercase |
| D4C8B1E6A2F7 | d4c8b1e6a2f7 | all letters converted to lowercase |
| 5F0A9D3C7E8B | 5f0a9d3c7e8b | all letters converted to lowercase |
| ZZYYXXWWVVUU | zzyyxxwwvvuu | all letters converted to lowercase |
| E2B7F5A9C3D0 | e2b7f5a9c3d0 | all letters converted to lowercase |
| NULL | NULL | a NULL input returns NULL |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `LOWER` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `LOWER` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generateLower` (inlines `BinaryStringData`'s `toLowerCase`) |

## Velox implementation

Velox already provides the builtin `lower` (`velox/functions/prestosql/registration/StringFunctionsRegistration.cpp`).
