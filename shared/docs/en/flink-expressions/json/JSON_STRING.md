# JSON_STRING

Category: [JSON](../index.md#json) | Aliases: —

## Role and scenarios

Serializes any SQL value — including nested ROWs and collection types — to JSON text; a row is encoded as a JSON array. The general-purpose encoder on the JSON construction side.

## Usage

Signature: `JSON_STRING(v)`

| Parameter | Type | Description |
|---|---|---|
| v | Any type | The SQL value to serialize |

Return: STRING; the JSON serialization of the value.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, JSON_STRING(ROW(1, 'a')) FROM bid;
```

Output: STRING; every row is '[1,"a"]' — the row is serialized as a JSON array.

| Input | Output | Notes |
|---|---|---|
| JSON_STRING(ROW(1, 'a')) | [1,"a"] | The row is serialized as a JSON array |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | no dedicated operator-table entry; resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | the `JSON_STRING` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | the dedicated `JsonStringCallGen`, serializing the value tree via the planner's JSON serializer |

## Velox implementation

The velox repository has no corresponding implementation yet; the closest, the `json_extract` family (`velox/functions/prestosql/registration/JsonFunctionsRegistration.cpp`), uses its own path syntax rather than the SQL/JSON standard.
