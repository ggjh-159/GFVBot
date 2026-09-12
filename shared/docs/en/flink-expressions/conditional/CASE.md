# CASE

Category: [Conditional](../index.md#conditional) | Aliases: —

## Role and scenarios

Branch selection. Searched form `CASE WHEN cond THEN val ... [ELSE val] END` evaluates conditions top-down and yields the first match; simple form `CASE expr WHEN v THEN ... END` compares against values. ELSE defaults to NULL. Row-level labeling and NULL-safe if/else logic.

## Usage

Input: `CASE WHEN cond THEN v [WHEN ...] [ELSE v] END` — branches must unify to one type.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, CASE WHEN bid.auction > 10 THEN 'high' ELSE 'low' END FROM bid;
```

Output: STRING; 'high' when `auction > 10`, else 'low' (data-dependent).

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

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

## Pipeline

The route of `CASE` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — CASE WHEN..THEN..ELSE..END; no dedicated FlinkSqlOperatorTable constant — the call is resolved through FunctionDefinitionOperatorTable, which adapts BuiltInFunctionDefinitions entries into SqlFunctions on the fly.
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:433, registered under the name "ifThenElse", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — Inlined by ExprCodeGenerator as a multi-branch if/else over the conditions (ScalarOperatorGens).
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
