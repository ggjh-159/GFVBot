# JSON_ARRAY

Category: [JSON](../index.md#json) | Aliases: —

## Role and scenarios

Builds a JSON array from the argument list and serializes it to text. NULL ON NULL keeps NULL elements as JSON null; ABSENT ON NULL omits them from the result. Used to collect column values into a JSON payload array.

## Usage

Signature: `JSON_ARRAY([v, ...] [NULL ON NULL | ABSENT ON NULL])`

| Parameter | Type | Description |
|---|---|---|
| v, ... | Any type | Array elements, JSON-encoded |

NULL ON NULL keeps NULL elements as JSON null; ABSENT ON NULL omits them.

Return: STRING; the serialized text of the JSON array.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, JSON_ARRAY(1, 2, 'a') FROM bid;
```

Output: STRING; every row is '[1,2,"a"]'.

| Input | Output | Notes |
|---|---|---|
| JSON_ARRAY(1, 2, 'a') | [1,2,"a"] | Numbers and strings are JSON-encoded |
| JSON_ARRAY(1, NULL NULL ON NULL) | [1,null] | NULL ON NULL: NULL elements are kept as JSON null |
| JSON_ARRAY(1, NULL ABSENT ON NULL) | [1] | ABSENT ON NULL: NULL elements are omitted |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `JSON_ARRAY` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `JSON_ARRAY` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | the dedicated `JsonArrayCallGen` |

## Velox implementation

The velox repository has no corresponding implementation yet; the closest, the `json_extract` family (`velox/functions/prestosql/registration/JsonFunctionsRegistration.cpp`), uses its own path syntax rather than the SQL/JSON standard.
