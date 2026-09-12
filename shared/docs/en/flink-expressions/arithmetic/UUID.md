# UUID

Category: [Arithmetic](../index.md#arithmetic) | Aliases: —

## Role and scenarios

Generates a fresh RFC 4122 type-4 (random) UUID string per call; non-deterministic. Synthetic keys and request ids.

## Usage

Input: `UUID()` — no arguments; 36-character STRING.

```sql
-- 16-row bounded bid source: auction BIGINT, bidder BIGINT, price DECIMAL(10,2), dateTime TIMESTAMP(3), extra STRING
SELECT auction, bidder, 0.908 * price + 10, UUID() FROM bid;
```

Output: STRING; a fresh 36-character UUID per row (non-deterministic).

Example (input -> output):

| Input | Output |
|---|
| — | 3f8a2c1e-9b4d-4c6a-8e2f-1a5b9d0c7e3a |

The output is re-drawn per row (non-deterministic); one draw shown.

## Pipeline

The route of `UUID` from SQL text to the executing operator (Flink 1.19.2):

1. **Parse** — zero-arg function UUID(); the parser emits the SqlNode and the operator is anchored at `FlinkSqlOperatorTable.UUID` (FlinkSqlOperatorTable.java:742).
2. **Definition** — the BuiltInFunctionDefinitions entry at BuiltInFunctionDefinitions.java:1110, registered under the name "uuid", kind SCALAR; the planner binds the parsed call to this definition.
3. **Planning** — Marked non-deterministic, so the planner neither folds it nor moves it across operators.
4. **Codegen** — StringCallGen's UUID case inlines a java.util.UUID.randomUUID() call.
5. **Execution** — compiled (Janino) into the operator of the consuming ExecNode: for a projection or filter, the TableStreamOperator subclass generated for StreamExecCalc (CodeGenOperatorFactory), evaluated per row in processElement; inside a join condition or aggregate argument it runs in the StreamExecJoin / StreamExecGroupAggregate operators instead. See [Pipeline overview](../index.md#pipeline-overview).
