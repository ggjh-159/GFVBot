# JSON_VALUE

Category: [JSON](../index.md#json) | Aliases: —

## Role and scenarios

Extracts the scalar located by an SQL/JSON path and returns it as a string (or the type given by RETURNING); the ON EMPTY/ON ERROR clauses decide the behavior when the path is missing or the type mismatches. Used to read concrete field values from JSON payloads.

## Usage

Signature: `JSON_VALUE(json, path [RETURNING t] [on empty/error])`

| Parameter | Type | Description |
|---|---|---|
| json | STRING | The JSON document text |
| path | STRING | The SQL/JSON path, pointing to a scalar |

The RETURNING clause specifies the return type; the ON EMPTY/ON ERROR clauses decide the behavior when the path is missing or the type mismatches.

Return: STRING (or the type given by RETURNING); the scalar is rendered in the target type.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, JSON_VALUE('{"a": 1}', '$.a') FROM bid;
```

Output: STRING; every row is '1' — the numeric scalar is rendered as text.

| Input | Output | Notes |
|---|---|---|
| JSON_VALUE('{"a": 1}', '$.a') | 1 | The numeric scalar is rendered as text |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `JSON_VALUE` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `JSON_VALUE` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | the dedicated `JsonValueCallGen` (planner's codegen/calls), handling ON EMPTY/ON ERROR |

## Velox implementation

The velox repository has no corresponding implementation yet; the closest, the `json_extract` family (`velox/functions/prestosql/registration/JsonFunctionsRegistration.cpp`), uses its own path syntax rather than the SQL/JSON standard.
