# JSON_EXISTS

Category: [JSON](../index.md#json) | Aliases: —

## Role and scenarios

Tests whether an SQL/JSON path locates at least one value in the document; returns TRUE when it does. Used for fast existence checks on JSON payloads.

## Usage

Signature: `JSON_EXISTS(json, path)`

| Parameter | Type | Description |
|---|---|---|
| json | STRING | The JSON document text |
| path | STRING | The SQL/JSON path |

Return: BOOLEAN; TRUE when the path locates at least one value.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, JSON_EXISTS('{"a": 1}', '$.a') FROM bid;
```

Output: BOOLEAN; every row is true — the path $.a exists.

| Input | Output | Notes |
|---|---|---|
| JSON_EXISTS('{"a": 1}', '$.a') | TRUE | The path $.a locates a value |
| JSON_EXISTS('{"a": 1}', '$.b') | FALSE | The path locates no value |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `JSON_EXISTS` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `JSON_EXISTS` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | calls a `BuiltInMethods` static method registered by `FunctionGenerator` via `MethodCallGen`, with no standalone runtime class |

## Velox implementation

The velox repository has no corresponding implementation yet; the closest, the `json_extract` family (`velox/functions/prestosql/registration/JsonFunctionsRegistration.cpp`), uses its own path syntax rather than the SQL/JSON standard.
