# Plan rewrite: how Flink ExecNodes become Velox plans

How gluten rewrites the physical plan without modifying any Flink jar: same-package shadow classes win the classloading race, and their `translateToPlanInternal` builds a Velox plan instead of a Flink operator. This page covers the mechanism, the coverage list, and what a new override needs.

```text
SQL
 |
 v
Flink compile line: Calcite parse + optimize
 |  RelNode tree -> ExecNode tree (physical plan)
 v
PlannerModule (gluten-flink loader module)
 |  unpacks two embedded jars to a temp dir:
 |    gluten-flink-planner.jar (thin, ~14 shadow classes) FIRST
 |    flink-table-planner.jar (the official planner) second
 v
PlannerComponentClassLoader
 |  classes under org.apache.flink... load ONLY from those two jars,
 |  and the gluten jar is searched first -> same name, gluten wins
 v
ServiceLoader -> DefaultPlannerFactory -> StreamPlanner (unmodified)
 |  every ExecNode StreamPlanner instantiates loads through the
 |  same classloader -> the shadow copies are what run
 v
shadow ExecNode classes (14 of them)
 |  translateToPlanInternal: input edge first, then build a velox4j
 |  PlanNode subtree, wrap it in GlutenOneInputOperator (plan only,
 |  no serialization, no JNI yet)
 v
Transformation -> StreamGraph   (web UI shows "gluten-calc" & friends)
```

| Stage | Entry point | Question answered |
|---|---|---|
| 1 Boot & isolation | `PlannerModule` constructor + `PlannerModule#loadPlannerFactory` (gluten-flink loader) | why the JVM loads gluten's copy of a same-named class |
| 2 Coverage | the shadow classes under `org.apache.flink.table.planner.plan.nodes.exec` (gluten-flink planner) | which ExecNodes are rewritten |
| 3 Rewrite template | `StreamExecCalc#translateToPlanInternal` (gluten-flink planner) | how a Calc becomes a FilterNode+ProjectNode subtree |
| 4 Source & sink | `StreamExecTableSourceScan`, `VeloxSourceSinkFactory#buildSource/buildSink` (gluten-flink runtime), `NexmarkSourceFactory` | how the two ends that touch external systems are swapped |

## Stage 1: classload isolation

JVM rule being exploited: a fully-qualified class name loads once; whoever loads first defines it. Flink already runs its table planner inside an isolated classloader; gluten arranges for its shadow jar to sit in front inside that same loader.

| Package prefix hits | Loaded from | Example |
|---|---|---|
| `COMPONENT_CLASSPATH` (`org.apache.flink`, `org.apache.gluten`, ...) | only the two embedded jars, gluten first | `StreamExecCalc` |
| `OWNER_CLASSPATH` (logging, janino, commons, hadoop) | the outer app classloader | slf4j |
| neither | component-only, no fallback to the outer loader | jackson |

The third row is why the planner jar must also stay in flink's `lib/`: ServiceLoader discovery of the source/sink factories runs on the outer classloader. Remove it and translation fails with a jackson `ClassNotFoundException`.

## Stage 2: what is covered

Shadow classes keep Flink's fields and `@ExecNodeMetadata` exactly (so JSON physical plans still load); only `translateToPlanInternal` changes.

| Shadow class | Velox plan nodes | Runtime operator |
|---|---|---|
| `StreamExecCalc` | `FilterNode` + `ProjectNode` | GlutenOneInputOperator ("gluten-calc") |
| `StreamExecTableSourceScan` | via source factory (e.g. `TableScanNode` + `NexmarkTableHandle`) | GlutenStreamSource |
| `StreamExecGroupAggregate` + 3 more aggregate nodes | `AggregationNode` | WindowAggOperator etc. |
| `StreamExecRank` | `TopNNode` | — |
| `StreamExecDeduplicate` | `DeduplicateNode` | — |
| `StreamExecJoin` / `StreamExecWindowJoin` | `TableScanNode` + `HashPartitionFunctionSpec` + `NestedLoopJoinNode` etc. | GlutenTwoInputOperator |
| `StreamExecExchange` | — (hash partitioning expressed) | named "exchange-hash" |
| `StreamExecWatermarkAssigner` | `ProjectNode` | — |
| `CommonExecSink` | via sink factory (e.g. `TableWriteNode`) | GlutenStreamingFileWriterOperator etc. |

## Stage 3: the rewrite template (StreamExecCalc)

Every shadow class follows the same four moves:

1. Translate the input edge first (`ExecEdge#translateToPlan`) so the upstream chain — possibly mixed native and gluten — is built before this node.
2. Build the Velox subtree: the WHERE condition becomes a `FilterNode`, the projection a `ProjectNode`, both rooted on an `EmptyNode` placeholder. The placeholder is deliberate: each gluten operator describes only its own segment; at runtime `open()` swaps the placeholder for an ExternalStream scan node fed from a queue (see [runtime execution](runtime-execution.md)).
3. Wrap the subtree in a `StatefulPlanNode` and hand it to a `GlutenOneInputOperator` holding nothing but the plan — no serialization, no JNI. All of that happens later on the TaskManager.
4. Return the Transformation. The only visible difference from native Flink is the operator name ("gluten-calc") in the web UI.

Notably absent: codegen. Native Flink compiles expressions into Java bytecode here; gluten leaves the expression tree intact for Velox to compile vectorized on the C++ side (see [expression mapping](expression-mapping.md)).

## Stage 4: source and sink rewrite

The two ends cannot be "pure computation", so they take a different route: let Flink build the native Transformation, then swap it whole.

- `StreamExecTableSourceScan#translateToPlanInternal` calls `super()` first (native SourceTransformation), extracts any watermark push-down spec, then hands the Transformation to `VeloxSourceSinkFactory#buildSource`.
- `buildSource`/`buildSink` find a factory two ways: ServiceLoader (the `lib/` discovery above), then a hardcoded `FACTORY_CLASS_NAMES` list loaded by reflection. Each factory has `match(transformation)` + `buildVeloxSource/...`.
- No factory matches -> warn and return the native Transformation unchanged: an unsupported source or sink silently degrades to native execution; the query still runs. (Contrast: expression mapping has no fallback — a missing mapping fails the query.)
- Example: `NexmarkSourceFactory` reflects the generator configs out of the native source, builds `TableScanNode` + `NexmarkTableHandle` + `NexmarkParallelSplit`, wraps them in `GlutenStreamSource`, and returns a `LegacySourceTransformation` that looks to StreamGraph like nothing happened.

## Adding a new ExecNode override

1. Same package path, same `@ExecNodeMetadata` name and version as the Flink original — no registration needed; loading order does the work.
2. In `translateToPlanInternal`, replace the identity-project example with real nodes: expressions via `RexNodeConverter#toTypedExpr` ([expression mapping](expression-mapping.md)); node types velox4j lacks need new PlanNode classes ([plan serialization](plan-serde.md)).
3. Source/sink-style nodes additionally need a factory (`match` + `buildVeloxSource`), registered in `VeloxSourceSinkFactory.FACTORY_CLASS_NAMES` and in the `META-INF/services` file.
4. Deployment: the planner jar has two identities — the thin jar embedded in the loader jar and the copy in flink `lib/` for ServiceLoader. Rebuild and replace both.

## Pitfalls

| Symptom | Cause | Fix |
|---|---|---|
| Web UI shows only native operators | shadow classes lost the classloading race (deployment order) | the overridden translator classes must sit at the front of the classpath |
| `ClassNotFoundException` for jackson during translation | planner jar missing from flink `lib/` (component-only loading does not fall back) | restore the planner jar to `lib/` |
| Job fails at plan load with a metadata error | shadow class `@ExecNodeMetadata` diverges from the Flink original | keep name/version byte-identical |
| A source or sink quietly runs native | no factory matched (not registered, or `match` too narrow) | check the warn log; register or widen `match` |
