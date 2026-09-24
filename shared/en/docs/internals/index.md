# GFV internals

Source-level deep dives into the GFV stack, one stage of the [architecture overview](../architecture.md) per page. Read the overview first; come here when a task needs to know how a stage actually works or where a new piece plugs in.

| Page | Stage of the overview | Answers |
|---|---|---|
| [Plan rewrite](plan-rewrite.md) | 2 | How gluten's shadow planner classes replace Flink operators with Velox plans, and what a new ExecNode override needs |
| [Expression mapping](expression-mapping.md) | 2 | How a RexNode expression becomes a Velox TypedExpr, and what a new function needs on each side |
| [Plan serialization](plan-serde.md) | 3-4 | How the plan crosses JNI as JSON and becomes C++ objects and an operator chain |
| [Runtime execution](runtime-execution.md) | 5-6 | The per-record data loop: chain slicing, Arrow bridging, the drive loop, watermarks, checkpoints, shutdown |
| [Stateful operators](stateful-operator.md) | 4-5 | The StatefulOperator framework: event model, composition shell, state and timer APIs, checkpoint/RocksDB pass-through |
| [Unit testing](unit-testing.md) | — | How tests are written and run in velox, velox4j, and gluten-flink |

Conventions across the series:

**Code references**: methods are written `Class#method` (e.g. `StatefulTask#next`); files are written as paths relative to the repo root (e.g. `gluten-flink/planner/.../StreamExecCalc.java`, where `...` stands for the omitted package directories). The four source repos (velox, velox4j, gluten, flink) are cloned under the workspace's `repos/` directory — grep a symbol inside the matching repo to locate its source.

**No line numbers**: line numbers go stale as soon as the source changes, while class and method names usually survive. Everything here is anchored by symbol name, so the pages remain valid across refactors.

**Page structure**: each page runs, in order — a short introduction (which question the page answers), one flow diagram, a stage table, then several mechanism sections; it always ends with two fixed sections: an "adding X" checklist (the ordered steps for plugging in a new piece) and a pitfalls table (three columns: symptom | cause | avoidance). Those two closing sections build on the mechanism sections above them, so read the page in order.
