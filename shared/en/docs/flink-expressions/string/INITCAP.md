# INITCAP

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Converts every whitespace-separated word in s to the form with an uppercase first letter and lowercase remaining letters, used to turn raw names into display form.

## Usage

Signature: `INITCAP(s)`

| Parameter | Type | Description |
|---|---|---|
| s | STRING | the string to convert |

Return: STRING; each word with an uppercase first letter and the rest lowercase.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, INITCAP('hello world') FROM bid;
```

Output: STRING; 'Hello World' on every row.

Examples (input → output):

| Input | Output | Notes |
|---|---|---|
| INITCAP('hello world') | Hello World | two whitespace-separated words, each with an uppercase first letter |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `INITCAP` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `INIT_CAP` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generateInitcap` (direct call to `SqlFunctionUtils`'s `initcap`) |

## Velox implementation

The velox repository has no corresponding implementation yet.
