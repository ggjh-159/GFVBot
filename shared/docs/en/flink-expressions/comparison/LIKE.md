# LIKE

Category: [Comparison](../index.md#comparison) | Aliases: —

## Role and scenarios

SQL wildcard match: `%` matches any run of characters, `_` exactly one; ESCAPE designates an escape character. Case-sensitive. Filtering names and ids by shape.

## Usage

Input: `s LIKE pattern [ESCAPE c]` — both strings; returns BOOLEAN.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.extra LIKE '%A%' FROM bid;
```

Output: BOOLEAN; true when `extra` contains an 'A' (data-dependent).

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| extra | extra LIKE '%A%' |
|---|---|
| A3F19C27B4E0 | TRUE |
| 8B2D4F90A1C3 | TRUE |
| C7E5A0D39F16 | TRUE |
| ZK9M2Q7XVBT5 | FALSE |
| D4C8B1E6A2F7 | TRUE |
| 5F0A9D3C7E8B | TRUE |
| ZZYYXXWWVVUU | FALSE |
| E2B7F5A9C3D0 | TRUE |

## Pipeline

The route of `LIKE` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — infix s LIKE pattern [ESCAPE c]; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.LIKE` (FlinkSqlOperatorTable.java:1165).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:768, registered under the name "like", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — No dedicated rewrite; as a plain RexCall it moves with the generic rules — filter/project push-down, CalcMergeRule, constant folding (ExpressionReducer) when fully literal.
4. **Codegen** — StringCallGen dispatches LIKE to LikeCallGen (caches the compiled pattern as a reusable operator member).
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
