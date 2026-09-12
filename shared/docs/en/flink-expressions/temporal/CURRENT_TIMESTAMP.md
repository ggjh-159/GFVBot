# CURRENT_TIMESTAMP

Category: [Temporal](../index.md#temporal) | Aliases: —

## Role and scenarios

The current instant as TIMESTAMP WITH LOCAL TIME ZONE, rendered in the session zone; evaluated once per query; no parentheses. Sibling of NOW().

## Usage

Input: `CURRENT_TIMESTAMP` — no parentheses; TIMESTAMP_LTZ.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, CURRENT_TIMESTAMP FROM bid;
```

Output: TIMESTAMP_LTZ; one fixed instant for the whole query — identical on all 16 rows.

Example (input -> output):

| Input | Output |
|---|
| — | 2026-09-11 10:23:41.209 |

One value per query — identical on all 16 rows.

## Pipeline

The route of `CURRENT_TIMESTAMP` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — keyword, no parentheses; no dedicated FlinkSqlOperatorTable constant — the call is resolved through FunctionDefinitionOperatorTable, which adapts BuiltInFunctionDefinitions entries into SqlFunctions on the fly.
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1772, registered under the name "currentTimestamp", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — CurrentTimePointCallGen — a query-level constant injected as a reusable member (streaming); folded at plan time in batch.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
