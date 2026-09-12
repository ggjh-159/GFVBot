# RAND

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Uniformly distributed DOUBLE in [0, 1); non-deterministic per row unless a seed is supplied, in which case the sequence is reproducible. Sampling, load spreading, synthetic columns.

## Usage

Input: `RAND()` or `RAND(seed)` — optional BIGINT seed.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, RAND() FROM bid;
```

Output: DOUBLE in [0.0, 1.0); re-drawn on every row (non-deterministic).

Example (input -> output):

| Input | Output |
|---|
| — | 0.5310239745577783 |

The output is re-drawn per row (non-deterministic); one draw shown.

## Pipeline

The route of `RAND` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — zero-arg or seeded function; the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.RAND` (FlinkSqlOperatorTable.java:940).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1661, registered under the name "rand", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — Marked non-deterministic, so the planner neither folds it nor moves it across operators.
4. **Codegen** — RandCallGen — generates a per-operator Random member (seeded variant is reproducible).
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
