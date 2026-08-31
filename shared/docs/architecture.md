# GFV architecture overview

GFV runs parts of a Flink job on the Velox C++ engine: Flink keeps responsibility for parsing, planning, scheduling, and checkpointing, while the executable core of suitable sub-plans is translated to Velox and executed natively. Three moving parts cooperate — gluten-flink (planner, loader, runtime modules inside the gluten repo), velox4j (the Java/JNI bridge), and velox itself (the engine).

## The path of one query

A Flink SQL or DataStream job first builds its stream graph the usual way. The gluten-flink planner then walks that graph, picks the sub-plans it can translate — projections, filters, aggregations, joins, window and ranking operators over the supported sources — and turns each of them into a Velox plan: operators, types, and expressions are mapped onto their Velox counterparts. Sub-plans it cannot translate stay on the Flink runtime, so a job typically runs as a mix of Velox and plain Flink stages.

The translated plan crosses into native code through velox4j: it wraps Velox plans, expressions, and data in Java objects and serializes them over JNI. On the native side velox executes the plan — batch execution goes through the native `exec` machinery (HashTable, RowContainer, vectorized aggregates), while streaming operators with state run in the `experimental/stateful` extension (keyed execution, state backends, watermark handling).

Data flows back as Arrow vectors across the C Data Interface, bridged by the gluten-flink runtime into Flink's data exchange, and results leave through the regular Flink sinks. The gluten-flink loader bootstraps the whole stack: with the jars in flink's `lib/`, the loader discovers and wires planner, runtime, and the native library at session start, so no extra cluster configuration is needed.

## Layer boundaries

| Layer | Language | Responsibility | Typical change |
|---|---|---|---|
| gluten-flink loader | Java | jar bootstrap, session wiring, native library loading | loading and classloader issues |
| gluten-flink planner | Java | Flink plan → Velox plan translation, operator and type mapping | supporting a new operator in plans |
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
