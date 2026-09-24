# SPLIT_INDEX

Category: [String](../index.md#string) | Aliases: —

## Role and scenarios

Splits the string s by the delimiter delim and returns the index-th piece (0-based), used to extract the field at a given position from a delimited string. An out-of-range index (outside `[0, piece_count - 1]`) or a negative one yields NULL rather than an error.

## Usage

Signature: `SPLIT_INDEX(s, delim, index)`

| Parameter | Type | Description |
|---|---|---|
| s | STRING | the string to split |
| delim | STRING | delimiter, matched literally |
| index | INT | 0-based piece index — the first piece is 0 |

Return: STRING; NULL when the index is out of range or negative.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, SPLIT_INDEX('a/b/c', '/', 1) FROM bid;
```

Output: STRING; 'b' on every row.

| Input | Output | Notes |
|---|---|---|
| SPLIT_INDEX('a/b/c', '/', 1) | b | 0-based index 1 is the second piece |
| SPLIT_INDEX('a/b/c', '/', 0) | a | index 0 is the first piece |
| SPLIT_INDEX('a/b/c', '/', 3) | NULL | out of range: 'a/b/c' has three pieces, valid indices are 0/1/2 |
| SPLIT_INDEX('a/b/c', '/', -1) | NULL | a negative index returns NULL |
| SPLIT_INDEX('abc', '/', 0) | abc | with no delimiter the whole string is one piece; index 0 returns it |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `SPLIT_INDEX` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | the `SPLIT_INDEX` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | `StringCallGen`'s `generateSplitIndex` (direct call to `SqlFunctionUtils`'s `splitIndex`) |

## Velox implementation

GFV already implements `split_index` on the velox side, registered in `velox/experimental/stateful/udf/Register.cpp` (implemented in `SplitIndex.h` in the same directory).
