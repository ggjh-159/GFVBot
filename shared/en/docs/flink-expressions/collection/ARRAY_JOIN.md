# ARRAY_JOIN

Category: [Collection](../index.md#collection) | Aliases: —

## Role and scenarios

Joins array elements into a single string with a delimiter. NULL elements are skipped by default; when nullReplacement is given, it joins in place of them; a NULL array itself yields NULL. Used to render tag lists into readable or CSV-like output.

## Usage

Signature: `ARRAY_JOIN(arr, delimiter[, nullReplacement])`

| Parameter | Type | Description |
|---|---|---|
| arr | ARRAY<T> | The array to join |
| delimiter | STRING | The delimiter between elements |
| nullReplacement | STRING | Optional; when given, joins in place of NULL elements |

Return: STRING; NULL elements are skipped by default, or replaced by nullReplacement when it is specified.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, ARRAY_JOIN(ARRAY['a','b'], '-') FROM bid;
```

Output: STRING; every row is 'a-b'.

| Input | Output | Notes |
|---|---|---|
| ARRAY_JOIN(ARRAY['a','b'], '-') | a-b | Joins the elements with '-' |
| ARRAY_JOIN(ARRAY['a',NULL,'b'], '-') | a-b | NULL elements are skipped by default |
| ARRAY_JOIN(ARRAY['a',NULL,'b'], '-', 'x') | a-x-b | The nullReplacement 'x' joins in place of NULL |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | no dedicated operator-table entry; resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | the `ARRAY_JOIN` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | the `eval()` of `ArrayJoinFunction` (flink-table-runtime, invoked via `BridgingSqlFunctionCallGen`) |

## Velox implementation

Velox already provides the builtin `array_join` (`velox/functions/prestosql/registration/ArrayFunctionsRegistration.cpp`).
