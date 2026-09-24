# CHR

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Produces the single-character string corresponding to the Unicode code point n, used to construct control or display characters from numbers.

## Usage

Signature: `CHR(n)`

| Parameter | Type | Description |
|---|---|---|
| n | INT | the Unicode code point |

Return: STRING; the single character corresponding to the code point.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, CHR(65) FROM bid;
```

Output: STRING; 'A' on every row.

Examples (input → output):

| Input | Output | Notes |
|---|---|---|
| CHR(65) | A | code point 65 corresponds to the character 'A' |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `CHR` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `CHR` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generateChr` (direct call to `SqlFunctionUtils`'s `chr`) |

## Velox implementation

Velox already provides the builtin `chr` (`velox/functions/prestosql/registration/StringFunctionsRegistration.cpp`).
