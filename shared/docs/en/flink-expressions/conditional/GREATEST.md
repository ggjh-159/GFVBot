# GREATEST

Category: [Conditional](../index.md#conditional) | Aliases: —

## Role and scenarios

Returns the maximum of its arguments; if any argument is NULL the result is NULL. Commonly used for cross-column normalization and clamping (for example, flooring a computed result).

## Usage

Signature: `GREATEST(v1, v2, ...)`

| Parameter | Type | Description |
|---|---|---|
| v1, v2, ... | Comparable type | Two or more values of the same type |

Return: the same type as the arguments; the maximum across all arguments; NULL if any argument is NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, GREATEST(bid.auction, bid.bidder, 7) FROM bid;
```

Output: BIGINT; each row takes the maximum of `auction`, `bidder`, and the constant 7.

Example (first 8 rows of the 16-row source, illustrative data, with a final NULL-boundary row appended; leading columns are inputs, the last two are each row's result and notes):

| auction | bidder | GREATEST(auction, bidder, 7) | Notes |
|---|---|---|---|
| 3 | 15 | 15 | Maximum comes from bidder |
| 19 | 7 | 19 | Maximum comes from auction |
| 8 | 8 | 8 | Maximum comes from auction and bidder |
| 1 | 42 | 42 | Maximum comes from bidder |
| 14 | 23 | 23 | Maximum comes from bidder |
| 7 | 2 | 7 | Maximum comes from auction and the constant 7 |
| 11 | 11 | 11 | Maximum comes from auction and bidder |
| 20 | 36 | 36 | Maximum comes from bidder |
| NULL | 8 | NULL | Any NULL argument yields NULL |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | No dedicated operator-table entry; the `BuiltInFunctionDefinitions` entry is resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | The `GREATEST` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | Inlined by `ExprCodeGenerator` via `generateGreatestLeast` into a per-argument comparison chain |

## Velox implementation

Velox already provides the builtin `greatest` (`velox/functions/prestosql/registration/GeneralFunctionsRegistration.cpp`) (NULL semantics differ: the velox version skips NULLs while the Flink version returns NULL when any argument is NULL).
