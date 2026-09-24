# GFV architecture overview

GFV runs parts of a Flink job on the Velox C++ engine: Flink keeps responsibility for parsing, planning, scheduling, and checkpointing, while the executable core of suitable sub-plans is translated to Velox and executed natively. Three moving parts cooperate — gluten-flink (planner, loader, runtime modules inside the gluten repo), velox4j (the Java/JNI bridge), and velox itself (the engine).

## The path of one query

```text
        SQL / DataStream job
                  |
                  v
          Flink compile line          Calcite parse + optimize:
                  |                   RelNode tree -> ExecNode tree
                  v
        gluten-flink planner          shadow ExecNode classes translate
                  |                   each suitable sub-plan into a Velox
                  v                   plan (velox4j PlanNode + TypedExpr);
        StreamGraph -> JobGraph       untranslated parts stay on Flink
                  |
                  v
        TaskManager: open()           one chain slice per gluten operator
                  |
                  v
        velox4j serde + JNI           plan -> JSON, crosses JNI once;
                  |                    afterwards only handles cross
                  v
        velox stateful core           deserialize -> StatefulPlanner assembles
                  |                   the StatefulOperator chain inside a
                  v                   single-threaded, pull-based StatefulTask
        data loop, per record         Flink RowData -> Arrow -> BlockingQueue
                  |                   -> Velox chain; results return as Arrow
                  v                   vectors and are bridged back row by row
        Flink sinks + checkpoint      regular sinks; barrier-triggered
                                    snapshots cover Velox state too
```

| # | Stage | What happens | Owned by |
|---|---|---|---|
| 1 | Compile | SQL becomes a physical ExecNode plan through Flink's usual Calcite pipeline | Flink table planner |
| 2 | Rewrite | Shadowed ExecNode classes turn each translatable sub-plan into a Velox plan; the rest keeps its Flink operators | gluten-flink planner |
| 3 | Ship | Translated plans ride inside gluten operators through StreamGraph and JobGraph; at `open()` the plan serializes to JSON and crosses JNI once | gluten-flink runtime + velox4j |
| 4 | Build | The C++ side deserializes the plan and assembles the operator chain in a pull-based `StatefulTask` | velox `experimental/stateful` |
| 5 | Execute | Every record is bridged to Arrow, pushed through a shared queue, and pulled through the Velox chain; outputs return as Arrow vectors | all layers |
| 6 | Output & checkpoint | Results leave through regular Flink sinks; checkpoint barriers snapshot Velox state alongside Flink state | Flink runtime |

Because translation picks sub-plans rather than whole jobs, a job typically runs as a mix of Velox and plain Flink stages.

## Layer boundaries

| Layer | Language | Responsibility | Typical change |
|---|---|---|---|
| gluten-flink loader | Java | jar bootstrap, session wiring, native library loading | loading and classloader issues |
| gluten-flink planner | Java | Flink plan -> Velox plan translation, operator and type mapping | supporting a new operator in plans |
| gluten-flink runtime | Java | operator execution driver, state integration, Arrow bridging | streaming semantics, state plumbing |
| velox4j | Java + JNI | plan/expression/data bridge, serialization across JNI | new APIs crossing the boundary |
| velox `exec` | C++ | batch operators, HashTable, RowContainer, aggregate kernels | batch execution and aggregate internals |
| velox `experimental/stateful` | C++ | stateful streaming operators, keyed state, backends, timers | stateful operator development |

Directory-level detail for each repo lives in the module map under the flink-velox-docs-search skill; this page and that map are kept complementary (call path here, paths there).

## What each scenario touches

- Stateless expression development: one function wired through three layers — velox `expression` kernels, velox4j exposure, gluten-flink expression translation.
- Stateful operator development: mostly planner translation plus velox `experimental/stateful` (operator, state, timers) with runtime bridging.
- Aggregate function development: velox aggregate kernels and the accumulate/merge/finalize chain, surfaced through planner translation and runtime batching.
- Performance optimization: the full stack under profiling — pick the bottleneck layer with the query reference and this map, then verify with the verification workflow.

## Further reading

The [internals](internals/index.md) series walks each stage of the diagram down to source level:

- [Plan rewrite](internals/plan-rewrite.md) — how shadowed planner classes replace Flink operators with Velox plans (stage 2)
- [Expression mapping](internals/expression-mapping.md) — how a RexNode expression becomes a Velox TypedExpr (stage 2)
- [Plan serialization](internals/plan-serde.md) — how the plan crosses JNI and becomes C++ objects (stages 3-4)
- [Runtime execution](internals/runtime-execution.md) — the per-record data loop, watermarks, checkpoints, shutdown (stages 5-6)
- [Stateful operators](internals/stateful-operator.md) — the StatefulOperator framework: state, timers, window flush (stage 4-5)
- [Unit testing](internals/unit-testing.md) — how tests are written and run in each of the three repos
