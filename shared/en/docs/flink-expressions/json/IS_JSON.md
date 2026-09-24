# IS_JSON

Category: [JSON](../index.md#json) | Aliases: `IS JSON`

## Role and scenarios

Infix predicate that tests whether text is valid JSON, with an optional type qualifier that accepts only one JSON kind: `v IS JSON [VALUE | ARRAY | OBJECT | SCALAR]`. Used as an admission check ahead of other JSON functions.

## Usage

Signature: `v IS JSON [VALUE | ARRAY | OBJECT | SCALAR]` — infix predicate form, not a function call.

| Parameter | Type | Description |
|---|---|---|
| v | STRING | The text to test |
| VALUE / ARRAY / OBJECT / SCALAR | — | Optional type qualifier; when omitted, any valid JSON is accepted |

Return: BOOLEAN; TRUE when the text is valid JSON and satisfies the type qualifier.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, '{"a": 1}' IS JSON FROM bid;
```

Output: BOOLEAN; every row is true.

| Input | Output | Notes |
|---|---|---|
| '{"a": 1}' IS JSON | TRUE | Valid JSON text |
| '{"a": 1}' IS JSON OBJECT | TRUE | Type qualifier OBJECT: the text is a JSON object |
| '{"a": 1}' IS JSON ARRAY | FALSE | Type qualifier ARRAY: the text is not a JSON array |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | no dedicated operator-table entry; resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | the `IS_JSON` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | calls a `BuiltInMethods` static method registered by `FunctionGenerator` via `MethodCallGen`, with no standalone runtime class |

## Velox implementation

The velox repository has no corresponding implementation yet; the closest, the `json_extract` family (`velox/functions/prestosql/registration/JsonFunctionsRegistration.cpp`), uses its own path syntax rather than the SQL/JSON standard.
