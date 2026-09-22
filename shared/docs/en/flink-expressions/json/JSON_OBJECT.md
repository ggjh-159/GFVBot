# JSON_OBJECT

Category: [JSON](../index.md#json) | Aliases: —

## Role and scenarios

Builds a JSON object from KEY VALUE pairs and serializes it to text; NULL ON NULL keeps NULL values as JSON null, while ABSENT ON NULL omits the key-value pair entirely. Used to assemble column data into event payloads.

## Usage

Signature: `JSON_OBJECT([k VALUE v, ...] [NULL ON NULL | ABSENT ON NULL])` — keys are STRING literals.

| Parameter | Type | Description |
|---|---|---|
| k | STRING literal | The key of the JSON object |
| v | Any type | The value for the key, JSON-encoded |

NULL ON NULL keeps NULL values as JSON null; ABSENT ON NULL omits the key-value pair.

Return: STRING; the serialized text of the JSON object.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, JSON_OBJECT('k' VALUE 42) FROM bid;
```

Output: STRING; every row is '{"k":42}'.

| Input | Output | Notes |
|---|---|---|
| JSON_OBJECT('k' VALUE 42) | {"k":42} | A single key-value pair |
| JSON_OBJECT('k' VALUE NULL NULL ON NULL) | {"k":null} | NULL ON NULL: the NULL value is kept as JSON null |
| JSON_OBJECT('k' VALUE NULL ABSENT ON NULL) | {} | ABSENT ON NULL: the key-value pair is omitted |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `JSON_OBJECT` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `JSON_OBJECT` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | the dedicated `JsonObjectCallGen` |

## Velox implementation

The velox repository has no corresponding implementation yet; the closest, the `json_extract` family (`velox/functions/prestosql/registration/JsonFunctionsRegistration.cpp`), uses its own path syntax rather than the SQL/JSON standard.
