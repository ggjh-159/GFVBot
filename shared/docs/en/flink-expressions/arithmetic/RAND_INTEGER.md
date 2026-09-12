# RAND_INTEGER

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Uniformly distributed INTEGER in [0, bound); an optional seed makes the sequence reproducible. Random bucket assignment and test data generation.

## Usage

Input: `RAND_INTEGER(bound)` or `RAND_INTEGER(seed, bound)` — bound INT.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, RAND_INTEGER(100) FROM bid;
```

Output: INTEGER in [0, 100); re-drawn on every row (non-deterministic).

Example (input -> output):

| Input | Output |
|---|
| RAND_INTEGER(100) | 42 |

The output is re-drawn per row (non-deterministic); one draw shown.

## Pipeline

The route of `RAND_INTEGER` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — function form; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.RAND_INTEGER` (FlinkSqlOperatorTable.java:960).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1670, registered under the name "randInteger", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — Marked non-deterministic, so the planner neither folds it nor moves it across operators.
4. **Codegen** — RandCallGen — generates a per-operator Random member (seeded variant is reproducible).
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
