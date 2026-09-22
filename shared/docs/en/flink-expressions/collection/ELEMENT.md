# ELEMENT

Category: [Collection](../index.md#collection) | Aliases: —

## Role and scenarios

Returns the sole element of a single-element array; an empty array yields NULL, and more than one element raises an error. Used to unwrap results known to hold a single value (such as subquery output).

## Usage

Signature: `ELEMENT(arr)`

| Parameter | Type | Description |
|---|---|---|
| arr | ARRAY<T> | The single-element array to unwrap |

Return: T (the element type); an empty array yields NULL, multiple elements raise an error.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, ELEMENT(ARRAY[bid.auction]) FROM bid;
```

Output: BIGINT; each row is the value of `auction`.

Example (first 8 rows of the 16-row source, illustrative data; leading columns are input columns, the last column is the result for that row):

| auction | ELEMENT(ARRAY[auction]) |
|---|---|
| 3 | 3 |
| 19 | 19 |
| 8 | 8 |
| 1 | 1 |
| 14 | 14 |
| 7 | 7 |
| 11 | 11 |
| 20 | 20 |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | the `ELEMENT` entry in `FlinkSqlOperatorTable` |
| Definition and type inference | no `BuiltInFunctionDefinitions` entry (type inference rides on the ELEMENT operator via Calcite) |
| Evaluation logic | inlined via the ELEMENT branch of `ExprCodeGenerator` (single-element read with cardinality check) |

## Velox implementation

The velox repository has no corresponding implementation yet.
