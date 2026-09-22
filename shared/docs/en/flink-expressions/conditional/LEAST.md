# LEAST

Category: [Conditional](../index.md#conditional) | Aliases: —

## Role and scenarios

Returns the minimum of its arguments; if any argument is NULL the result is NULL. Used for capping (for example, limiting a discount to an upper bound).

## Usage

Signature: `LEAST(v1, v2, ...)`

| Parameter | Type | Description |
|---|---|---|
| v1, v2, ... | Comparable type | Two or more values of the same type |

Return: the same type as the arguments; the minimum across all arguments; NULL if any argument is NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, LEAST(bid.auction, bid.bidder, 60) FROM bid;
```

Output: BIGINT; each row takes the minimum of `auction`, `bidder`, and the constant 60.

Example (first 8 rows of the 16-row source, illustrative data, with a final NULL-boundary row appended; leading columns are inputs, the last two are each row's result and notes):

| auction | bidder | LEAST(auction, bidder, 60) | Notes |
|---|---|---|---|
| 3 | 15 | 3 | Minimum comes from auction |
| 19 | 7 | 7 | Minimum comes from bidder |
| 8 | 8 | 8 | Minimum comes from auction and bidder |
| 1 | 42 | 1 | Minimum comes from auction |
| 14 | 23 | 14 | Minimum comes from auction |
| 7 | 2 | 2 | Minimum comes from bidder |
| 11 | 11 | 11 | Minimum comes from auction and bidder |
| 20 | 36 | 20 | Minimum comes from auction |
| NULL | 8 | NULL | Any NULL argument yields NULL |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | No dedicated operator-table entry; the `BuiltInFunctionDefinitions` entry is resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | The `LEAST` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | Inlined by `ExprCodeGenerator` via `generateGreatestLeast` into a per-argument comparison chain |

## Velox implementation

Velox already provides the builtin `least` (`velox/functions/prestosql/registration/GeneralFunctionsRegistration.cpp`) (NULL semantics differ: the velox version skips NULLs while the Flink version returns NULL when any argument is NULL).
