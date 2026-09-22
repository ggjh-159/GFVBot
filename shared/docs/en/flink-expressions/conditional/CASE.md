# CASE

Category: [Conditional](../index.md#conditional) | Aliases: —

## Role and scenarios

Branch-selection expression: WHEN conditions are evaluated top to bottom and the value of the first branch that evaluates to TRUE is returned; when none is satisfied, the ELSE value is returned, or NULL if ELSE is omitted. The searched form `CASE WHEN cond THEN val ... END` selects a branch by condition; the simple form `CASE expr WHEN v THEN val ... END` compares expr for equality against each v in turn. Condition evaluation follows three-valued logic: a result of UNKNOWN is treated as not satisfied and the next branch is considered — testing for nulls therefore requires `IS NULL`; `expr = NULL` always evaluates to UNKNOWN and matches no branch.

## Usage

Grammar: `CASE WHEN cond THEN v [WHEN ...] [ELSE v] END` (searched form) or `CASE expr WHEN v THEN r [WHEN ...] [ELSE r] END` (simple form) — branch results must unify to a single type.

| Component | Description |
|---|---|
| WHEN cond / WHEN v | Evaluated top to bottom; the first branch that is TRUE takes effect, and later branches are not evaluated |
| THEN v / THEN r | The value returned when the owning branch takes effect |
| ELSE v | The value returned when no branch is satisfied; omitted means NULL |

Return: the value of the branch that takes effect; the type is the common type of the branch results.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, CASE WHEN bid.auction > 10 THEN 'high' ELSE 'low' END FROM bid;
```

Output: STRING; 'high' when `auction > 10`, otherwise 'low' (varies with row data).

Example (first 8 rows of the 16-row source, illustrative data; leading columns are inputs, the last column is each row's result):

| auction | CASE WHEN auction > 10 THEN 'high' ELSE 'low' END |
|---|---|
| 3 | low |
| 19 | high |
| 8 | low |
| 1 | low |
| 14 | high |
| 7 | low |
| 11 | high |
| 20 | high |

## Source locations

The Flink 1.19.2 source anchors to consult when implementing the velox side of this function in GFV:

| Stage | Location |
|---|---|
| Parser recognition | No dedicated operator-table entry; the `BuiltInFunctionDefinitions` entry is resolved via `FunctionCatalogOperatorTable` |
| Definition and type inference | The `IF` entry in `BuiltInFunctionDefinitions` (SCALAR) |
| Evaluation logic | Multi-branch if/else inlined by `ScalarOperatorGens` |

## Velox implementation

The velox expression kernel handles it as the special forms `if`/`switch` (`velox/expression/RegisterSpecialForm.cpp`), with no standalone function registration.
