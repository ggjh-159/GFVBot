# IN

Category: [Comparison](../index.md#comparison) | Aliases: —

## Role and scenarios

TRUE when the left operand equals any element of the value list; when nothing matches but any element (or the operand) is NULL, the result is UNKNOWN. Handy for small allow-lists and deny-lists; the planner may rewrite it into a SEARCH/SARG lookup.

## Usage

Input: `x IN (v1, v2, ...)` — x and the literals of a common comparable type; empty-match plus NULL yields UNKNOWN.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.auction IN (1, 5, 9, 13) FROM bid;
```

Output: BOOLEAN; true when `auction` is 1, 5, 9, or 13 (data-dependent).

Example (first 8 of the 16 source rows, illustrative; input columns followed by the result column):

| auction | auction IN (1, 5, 9, 13) |
|---|---|
| 3 | FALSE |
| 19 | FALSE |
| 8 | FALSE |
| 1 | TRUE |
| 14 | FALSE |
| 7 | FALSE |
| 11 | FALSE |
| 20 | FALSE |

## Pipeline

The route of `IN` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — keyword IN (..); the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.IN` (FlinkSqlOperatorTable.java:1171).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:2381, registered under the name "in", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — Rewritten during Sql-to-Rex conversion into a SEARCH RexCall (SARG range); at codegen SearchOperatorGen expands it back into interval comparisons.
4. **Codegen** — Inlined by ExprCodeGenerator into plain Java operator code (ScalarOperatorGens); no separate runtime class.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
