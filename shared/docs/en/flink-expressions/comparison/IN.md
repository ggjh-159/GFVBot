# IN

Category: [Comparison](../index.md#comparison) | Aliases: —

## Role and scenarios

Returns TRUE as soon as the left operand equals any element of the list; when there is no match and any element (or the operand) is NULL, the result is UNKNOWN. Suited to small whitelist/blacklist filtering; the planner may rewrite it into a SEARCH/SARG lookup.

## Usage

Signature: `x IN (v1, v2, ...)` — x is the expression under test; v1, v2, ... are list elements of the same comparable type as x.

Return: BOOLEAN; TRUE when x equals any element; UNKNOWN when there is no match and a NULL appears anywhere.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.auction IN (1, 5, 9, 13) FROM bid;
```

Output: BOOLEAN; true when `auction` is 1, 5, 9, or 13 (varies with row data).

Example (first 8 rows of the 16-row source, illustrative data, with a final NULL-boundary row appended; leading columns are inputs, the last two are each row's result and notes):

| auction | auction IN (1, 5, 9, 13) | Notes |
|---|---|---|
| 3 | FALSE | No match and no NULL in the list, so FALSE |
| 19 | FALSE | No match |
| 8 | FALSE | No match |
| 1 | TRUE | Matches list element 1 |
| 14 | FALSE | No match |
| 7 | FALSE | No match |
| 11 | FALSE | No match |
| 20 | FALSE | No match |
| NULL | UNKNOWN | No match and the operand is NULL, so UNKNOWN |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | The `IN` entry in `FlinkSqlOperatorTable`; rewritten to a SEARCH RexCall (SARG range) during Sql-to-Rex conversion |
| Definition and type inference | The `IN` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | After the rewrite to SEARCH, expanded into interval comparisons by `SearchOperatorGen` |

## Velox implementation

Velox already provides the builtin `in` (`velox/functions/prestosql/registration/GeneralFunctionsRegistration.cpp`).
