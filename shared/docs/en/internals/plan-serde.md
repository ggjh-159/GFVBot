# Plan serialization: from Java plan to C++ operator chain

What happens between "the planner built a velox4j PlanNode tree" and "a Velox operator chain is running": the tree serializes to name-polymorphic JSON, crosses JNI once as a string, deserializes by name into C++ objects, and the StatefulPlanner assembles the executable chain. Also covers how the nexmark source and the print sink plug into this path.

```text
Java (GlutenOneInputOperator#initSession)          C++ (velox4j / velox)
  StatefulPlanNode tree
   |-- mock TableScanNode(ExternalStreamTableHandle)
   |      + addTarget(real plan subtree)
   v
  Serde.toJson  --- one JSON string across JNI --->  folly::parseJson
   |   PolymorphicSerializer                          |
   |   injects "name": "ProjectNode" ...              v
   ISerializableRegistry                        ISerializable::deserialize<Query>
   (Java name <-> class table)                  (C++ name <-> factory table)
                                                        |
                                                        v
                                          StatefulQueryExecutor -> StatefulTask::create
                                                        |        (kSerial, pull-based)
                                                        v
                                          StatefulPlanner::plan -> StatefulOperator chain
                                          (each shell wraps a native exec::Operator)
```

| Stage | Entry point | Question answered |
|---|---|---|
| 1 Java serialization | `Serde#toJson`, `PolymorphicSerializer`, `ISerializableRegistry` (velox4j `serde/`, `serializable/`) | how a polymorphic tree becomes JSON, and where new classes register |
| 2 JNI boundary | `JniWrapper.createQueryExecutor` (velox4j, Java + `JniWrapper.cc`) | what actually crosses the boundary |
| 3 C++ deserialization | `ISerializable::deserialize`, per-class `registerSerDe()` (velox `common/serialization/Serializable.h`) | how JSON becomes `core::PlanNode` objects |
| 4 Chain assembly | `StatefulQueryExecutor` -> `StatefulTask::init` -> `StatefulPlanner::plan` (velox4j, velox `experimental/stateful/`) | how PlanNodes become executable operators |
| 5 Connectors | `NexmarkConnector`, `ExternalStream`, print sink (velox `experimental/connectors/`) | how source and sink plug in |

## Stage 1: name-polymorphic serialization

Every object crossing JNI implements `NativeBean`; the serializer writes a `"name"` field (e.g. `"ProjectNode"`) before the object's own fields, and the deserializer routes on it. Registration happens in the static block of `ISerializableRegistry` — three groups: expressions (`CallTypedExpr` etc.), connector handles (`NexmarkTableHandle`), plan nodes (`ProjectNode`, `TableScanNode`, `StatefulPlanNode`, `EmptyNode`, the stateful nodes). No annotations; **registering is naming** — an unregistered class fails serialization outright.

Two structural facts to carry around:

- Each gluten operator's plan needs a source (Velox rejects source-less plans), but the real data arrives from Flink. So `initSession` wraps the actual subtree as a target of a mock `TableScanNode(ExternalStreamTableHandle)` — the pull-based scan that a queue feeds ([runtime execution](runtime-execution.md)). The planner-stage `EmptyNode` placeholder is redeemed here.
- `StatefulPlanNode` is "entry node + downstream target list" — it lets a linear operator chain be expressed as a list and has a same-named C++ counterpart.

The debug log line `"Gluten Plan: {}"` in `initSession` prints the whole JSON — the first stop when a plan looks wrong, and ready-made input for a serde round-trip test ([unit testing](unit-testing.md)).

## Stage 2: the JNI boundary

`queryOps().execute(query)` bottoms out in the native `createQueryExecutor(String)`. The payload is a JSON string — once. The C++ side parses, deserializes the `Query`, creates a `StatefulQueryExecutor`, and stores it in the session's `ObjectStore`; the returned 64-bit handle is what every later call (advance, get, snapshot...) passes instead of the plan. The native library itself loads on first velox4j class touch (the `Initializing Velox4J` log line in the TaskManager log).

## Stage 3: deserialization by name

Each `ISerializable` subclass registers a static `create(const folly::dynamic&, void*)` factory into the deserialization registry; `deserialize<T>` reads the `"name"` field and looks it up. The Java and C++ registries are symmetric; **the name string is the only contract**. Registration points:

- generic plan nodes: `PlanNode::registerSerDe()` in `velox/core/PlanNode.cpp` (~30 nodes)
- stateful extension nodes: `StatefulPlanNode.cpp`'s registerSerDe — `StatefulPlanNode` itself (recursively deserializing `node` + `targets`), `EmptyNode`, `WatermarkAssignerNode`, `StreamJoinNode`, `GroupAggregationNode`, `DeduplicateNode`, ...
- connector handles/splits: in each connector's cpp, with `registerConnectors()` binding `connector-nexmark`, `connector-external-stream`, ... to factories

All `registerSerDe` calls run during velox4j init — a new C++ node type is "class + one Register line", no central config.

## Stage 4: StatefulPlanner assembles the chain

`StatefulQueryExecutor` wraps the plan in a `PlanFragment` + `QueryCtx`, calls `StatefulTask::create` — an `exec::Task` subclass pinned to `ExecutionMode::kSerial` ([stateful operators](stateful-operator.md)) — then `StatefulTask#init` -> `initOperators` -> `StatefulPlanner::plan`.

Dispatch is a type ladder over the inner node: stateful-specific nodes get custom transforms (watermark assigner, stream join, group/window aggregation, ...); everything else falls to `transformGenericOperator` -> `transformOperator`, which maps PlanNodes onto native operators:

| PlanNode(s) | Native operator |
|---|---|
| `FilterNode` (+ following `ProjectNode`) | `exec::FilterProject` — the two fuse; this is what "gluten-calc" really is |
| `TableScanNode` | `exec::TableScan` |
| `HashJoinNode` | `exec::HashProbe` |
| `AggregationNode` | `exec::StreamingAggregation` |
| `TopNNode` | `exec::TopN` |

A final fallback consults `exec::Operator::operatorSupplierFromPlanNode` — the extension point via `Operator::registerOperator`.

## Stage 5: connectors

- **nexmark source**: `TableScanNode` + `NexmarkTableHandle("connector-nexmark")` -> `NexmarkConnector`; `addSplit` receives the `NexmarkParallelSplit` built at plan time, and `next()` drives the generator by wallclock. Generation and shuffling stay in C++.
- **print sink**: `TableWriteNode("connector-print")` -> C++ writes to stdout directly; the `N> +I[...]` lines in the TaskManager `.out` log are its output, `N>` being the sink subtask index. These bypass the Java collector entirely ([runtime execution](runtime-execution.md)).
- **stream input**: `ExternalStreamTableHandle` -> `ExternalStream` connector pulling Arrow batches from the shared `BlockingQueue`.

## Adding a new plan node or connector

New plan node type:

1. velox4j: a `PlanNode` subclass under `plan/` (fields are the JSON fields); register in `ISerializableRegistry`'s plan-node group.
2. velox: the matching `core::PlanNode` subclass with `serialize()` and `static create(...)`; register in the appropriate `registerSerDe()` — the name must match the Java side exactly.
3. Translation: if `transformGenericOperator` cannot map it, add a branch in `StatefulPlanner` ([stateful operators](stateful-operator.md) for the full operator API).
4. The gluten-side code that constructs the node is the ExecNode override step ([plan rewrite](plan-rewrite.md)).

New connector: Java split/handle subclasses + registry entries; a C++ `connector::Connector` with `addSplit` and a data cursor, registered under `connector-myname`; and a `VeloxSourceSinkFactory` implementation on the Flink side.

## Pitfalls

| Symptom | Cause | Fix |
|---|---|---|
| `not registered` during serialization | Java class missing from `ISerializableRegistry` | add the entry — registration is naming |
| deserialization rejects an unknown `name` | C++ `registerSerDe` missing, or the two sides spell the name differently | names must match byte-for-byte both sides |
| plan JSON suspicion | — | grab the `"Gluten Plan: {}"` debug output and diff against expectations; feed it into a serde round-trip test |
| unexpected operator in the running chain | a transform branch caught (or missed) the node | check the `StatefulPlanner` dispatch ladder before suspecting serde |
