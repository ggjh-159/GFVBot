# UPPER

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Converts the string s entirely to uppercase, used to normalize case before comparison or grouping when sources mix letter cases. Returns NULL when s is NULL.

## Usage

Signature: `UPPER(s)`

| Parameter | Type | Description |
|---|---|---|
| s | STRING/CHAR | the string to convert |

Return: STRING; the fully uppercased result; a NULL input yields NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, UPPER(bid.extra) FROM bid;
```

Output: STRING; the 12 characters of `extra` uppercased on every row (varies with the row data).

Examples (first 8 rows of the 16-row source, illustrative data; leading columns are the input columns, the last column is the result for that row):

| extra | UPPER(extra) | Notes |
|---|---|---|
| A3F19C27B4E0 | A3F19C27B4E0 | the input is already uppercase; the result is unchanged |
| 8B2D4F90A1C3 | 8B2D4F90A1C3 | the input is already uppercase; the result is unchanged |
| C7E5A0D39F16 | C7E5A0D39F16 | the input is already uppercase; the result is unchanged |
| ZK9M2Q7XVBT5 | ZK9M2Q7XVBT5 | the input is already uppercase; the result is unchanged |
| D4C8B1E6A2F7 | D4C8B1E6A2F7 | the input is already uppercase; the result is unchanged |
| 5F0A9D3C7E8B | 5F0A9D3C7E8B | the input is already uppercase; the result is unchanged |
| ZZYYXXWWVVUU | ZZYYXXWWVVUU | the input is already uppercase; the result is unchanged |
| E2B7F5A9C3D0 | E2B7F5A9C3D0 | the input is already uppercase; the result is unchanged |
| NULL | NULL | a NULL input returns NULL |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `UPPER` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `UPPER` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generateUpper` (inlines `BinaryStringData`'s `toUpperCase`) |

## Velox implementation

Velox already provides the builtin `upper` (`velox/functions/prestosql/registration/StringFunctionsRegistration.cpp`).
