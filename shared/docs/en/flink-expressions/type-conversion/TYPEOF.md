# TYPEOF

Category: [Type Conversion](../index.md#type-conversion) | Aliases: —

## Role and scenarios

Returns the runtime type of its argument as a STRING (e.g. `BIGINT NOT NULL`); an optional force flag evaluates the argument's SQL text as written. Debugging inferred types in dynamic schemas.

## Usage

Input: `TYPEOF(x)` or `TYPEOF(x, force)` — any input; returns STRING.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, TYPEOF(bid.auction) FROM bid;
```

Output: STRING; 'BIGINT NOT NULL' on every row.

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| auction | TYPEOF(auction) |
|---|---|
| 3 | BIGINT NOT NULL |
| 19 | BIGINT NOT NULL |
| 8 | BIGINT NOT NULL |
| 1 | BIGINT NOT NULL |
| 14 | BIGINT NOT NULL |
| 7 | BIGINT NOT NULL |
| 11 | BIGINT NOT NULL |
| 20 | BIGINT NOT NULL |

## Pipeline

The route of `TYPEOF` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; no dedicated FlinkSqlOperatorTable constant — the call is resolved through FunctionDefinitionOperatorTable, which adapts BuiltInFunctionDefinitions entries into SqlFunctions on the fly.
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:114, registered under the name "TYPEOF", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — BridgingSqlFunctionCallGen invokes eval() on the table-runtime class scalar/TypeOfFunction (flink-table-runtime, new-stack carrier).
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
