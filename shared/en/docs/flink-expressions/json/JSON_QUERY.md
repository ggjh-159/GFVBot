# JSON_QUERY

Category: [JSON](../index.md#json) | Aliases: —

## Role and scenarios

Extracts the JSON object or array located by an SQL/JSON path and returns it as JSON text; the WRAPPER clause controls whether the result is wrapped in another JSON array. Used to fetch sub-documents rather than scalars.

## Usage

Signature: `JSON_QUERY(json, path [RETURNING t] [wrapper] [on empty/error])`

| Parameter | Type | Description |
|---|---|---|
| json | STRING | The JSON document text |
| path | STRING | The SQL/JSON path, pointing to an object or array |

The RETURNING clause specifies the return type; the WRAPPER clause controls whether the result is wrapped in another JSON array; the ON EMPTY/ON ERROR clauses decide the behavior when the path result is empty and when evaluation raises an error.

Return: STRING; the serialized text of the JSON sub-document.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, JSON_QUERY('{"a": {"b": 1}}', '$.a') FROM bid;
```

Output: STRING; every row is the sub-object '{"b": 1}'.

| Input | Output | Notes |
|---|---|---|
| JSON_QUERY('{"a": {"b": 1}}', '$.a') | {"b": 1} | Extracts the sub-object at path $.a and returns it as JSON text |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `JSON_QUERY` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `JSON_QUERY` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | calls a `BuiltInMethods` static method registered by `FunctionGenerator` via `MethodCallGen`, with no standalone runtime class |

## Velox implementation

The velox repository has no corresponding implementation yet; the closest, the `json_extract` family (`velox/functions/prestosql/registration/JsonFunctionsRegistration.cpp`), uses its own path syntax rather than the SQL/JSON standard.
