# PARSE_URL

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Extracts the specified part from a URL, where part is one of PROTOCOL, HOST, PATH, QUERY, REF, AUTHORITY, or FILE; when part is QUERY and a key is given, the value of that query parameter is returned, used for log and source analysis.

## Usage

Signature: `PARSE_URL(url, part[, key])`

| Parameter | Type | Description |
|---|---|---|
| url | STRING | the URL to parse |
| part | STRING | the part to extract, values as above |
| key | STRING | optional, the query parameter name, used with part 'QUERY' |

Return: STRING; the corresponding part of the URL or the value of the query parameter.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, PARSE_URL('http://h/p?a=1#f', 'QUERY', 'a') FROM bid;
```

Output: STRING; '1' on every row (the value of query parameter a).

Examples (input → output):

| Input | Output | Notes |
|---|---|---|
| PARSE_URL('http://h/p?a=1#f', 'QUERY', 'a') | 1 | with part 'QUERY' and a key given, returns the value of query parameter a |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `PARSE_URL` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `PARSE_URL` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generateParserUrl` (direct call to `SqlFunctionUtils`'s `parseUrl`) |

## Velox implementation

The velox repository has no corresponding implementation yet; the closest are the `url_extract_host` family (`velox/functions/prestosql/registration/URLFunctionsRegistration.cpp`).
