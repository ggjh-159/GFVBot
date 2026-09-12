# IS_TRUE

Category: [Logical](../index.md#logical) | Aliases: —

## Role and scenarios

Normalizes three-valued logic to two-valued: TRUE only for an input that is exactly TRUE; FALSE and UNKNOWN both map to FALSE. The explicit way to say treat-unknown-as-false.

## Usage

Input: `x IS TRUE` — x of BOOLEAN (possibly NULL); result is never NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, (bid.auction > 10 IS TRUE) FROM bid;
```

Output: BOOLEAN; the per-row truth of `auction > 10` (data-dependent).

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| auction | auction > 10 IS TRUE |
|---|---|
| 3 | FALSE |
| 19 | TRUE |
| 8 | FALSE |
| 1 | FALSE |
| 14 | TRUE |
| 7 | FALSE |
| 11 | TRUE |
| 20 | TRUE |

## Pipeline

The route of `IS_TRUE` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — postfix IS TRUE; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.IS_TRUE` (FlinkSqlOperatorTable.java:1109).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:528, registered under the name "isTrue", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — Inlined by ExprCodeGenerator into plain Java operator code (ScalarOperatorGens); no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
