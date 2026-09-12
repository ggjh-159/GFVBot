# TRY_CAST

Category: [Type Conversion](../index.md#type-conversion) | Aliases: —

## Role and scenarios

The same conversion matrix as CAST, but any conversion failure yields NULL instead of an error. Scrubbing dirty columns without killing the job.

## Usage

Input: `TRY_CAST(x AS t)` — t a concrete SQL type; failure yields NULL.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, TRY_CAST('bid.extra' AS INT) FROM bid;
```

Output: INT; NULL on every row — the literal 'bid.extra' is not a valid integer.

Example (input -> output):

| Input | Output |
|---|
| TRY_CAST('bid.extra' AS INT) | NULL |

## Pipeline

The route of `TRY_CAST` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — TRY_CAST(x AS t); the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.TRY_CAST` (FlinkSqlOperatorTable.java:938).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:2400, registered under the name "TRY_CAST", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — Same CAST codegen path wrapped so that a conversion failure yields NULL instead of an exception.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
