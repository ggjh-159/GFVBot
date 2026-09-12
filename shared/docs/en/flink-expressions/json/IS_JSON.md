# IS_JSON

Category: [JSON](../index.md#json) | Aliases: `IS JSON`

## Role and scenarios

Infix predicate testing whether the text is valid JSON, optionally of a given kind: `v IS JSON [VALUE | ARRAY | OBJECT | SCALAR]`. Gatekeeping before the other JSON functions.

## Usage

Input: `v IS JSON [kind]` — v STRING; returns BOOLEAN.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, '{"a": 1}' IS JSON FROM bid;
```

Output: BOOLEAN; true on every row.

Example (input -> output):

| Input | Output |
|---|
| '{"a": 1}' IS JSON | TRUE |

## Pipeline

The route of `IS_JSON` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — infix v IS JSON [kind]; no dedicated FlinkSqlOperatorTable constant — the call is resolved through FunctionDefinitionOperatorTable, which adapts BuiltInFunctionDefinitions entries into SqlFunctions on the fly.
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:2225, registered under the name "IS_JSON", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — MethodCallGen on a FunctionGenerator-registered BuiltInMethods static helper; no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
