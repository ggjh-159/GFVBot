# STR_TO_MAP

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Parses s into a MAP<STRING, STRING>, with pairDelim separating the key-value pairs and kvDelim separating each key from its value, used to turn serialized tag or parameter strings back into queryable maps.

## Usage

Signature: `STR_TO_MAP(s[, pairDelim[, kvDelim]])`

| Parameter | Type | Description |
|---|---|---|
| s | STRING | the string to parse |
| pairDelim | STRING | optional, the delimiter between key-value pairs |
| kvDelim | STRING | optional, the delimiter between key and value |

Return: MAP<STRING, STRING>; the parsed map.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, STR_TO_MAP('a=1,b=2', ',', '=') FROM bid;
```

Output: MAP<STRING, STRING>; {a=1, b=2} on every row.

Examples (input → output):

| Input | Output | Notes |
|---|---|---|
| STR_TO_MAP('a=1,b=2', ',', '=') | {a=1, b=2} | pairs separated by ',' and key from value by '=' |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `STR_TO_MAP` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `STR_TO_MAP` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generateStrToMap` (direct call to `SqlFunctionUtils`'s `strToMap`) |

## Velox implementation

Velox already provides an implementation: the sparksql suite's `str_to_map` (`velox/functions/sparksql/registration/RegisterString.cpp`).
