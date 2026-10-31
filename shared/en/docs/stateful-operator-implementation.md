# Stateful operator implementation guide

The implementation contract for new stateful operators: what the typed keyed state backend guarantees, what the operator implements, and how state management is delegated to the backend. This is the primary technical reference for the spec and design stages; for the operator shell, the event model, and task-driven execution see [internals/stateful-operator.md](internals/stateful-operator.md).

## Overview

```text
gluten planner (Java)                velox native (C++)
──────────────────────              ─────────────────────────────────────────
shadow ExecNode                     StatefulTask
  builds operator node               ├─ initializeState (params, records)
  +KeyedStateSpec                   │    ├─ task-level StateBackend (Heap|RocksDB)
  wrapped in StatefulPlanNode        │    ├─ chain initializeStateBackend
  JSON across JNI ───────────►       │    └─ restoreState → initializeState
GlutenOneInputOperator              StatefulOperator (keyed operator)
(Flink side stays non-keyed)          ├─ initialize()               stateless setup
                                      ├─ initializeStateBackend()   builds keyed backend
                                      ├─ addInput(StreamElement)    main path
                                      └─ close()
                                    HeapKeyedStateBackend<RowContainerStateKey>
                                      ├─ KeyTable: single key identity
                                      ├─ handle registry (one name one state)
                                      └─ snapshot()/restore(): key-group blocks
```

| Layer | Responsibility |
|---|---|
| Plan (gluten+velox4j) | operator node, `KeyedStateSpec` (key channels+types, pure plan data), serde mirror |
| Task (`StatefulTask`) | `KeyedStateBackendParameters` (maxParallelism and key-group sub-range), backend type choice, checkpoint orchestration |
| Operator (`StatefulOperator` subclass) | lifecycle implementation, business logic, changelog semantics, descriptors and callbacks |
| Backend (`HeapKeyedStateBackend`) | key identity and probing, key-group sharding, state access, materialization callbacks, checkpoint I/O, dead-key reclaim |

## Backend contract

Guarantees the backend takes over once state is delegated to it:

| Guarantee | Mechanism |
|---|---|
| unique key identity | the backend owns the single KeyTable at construction (key RowContainer+hash table+serializer); probing goes through `HashTable::groupProbe` — hash only buckets, hits compare columns exactly, colliding keys never merge |
| stable sharding | `keyGroup = hash % maxParallelism`; the backend owns only the `[startKeyGroup, start+num)` sub-range; maxParallelism never changes over the lifetime, rescale does not move boundaries |
| batch miss materialization | handle `rows()` resolves in batches; missing keys materialize new rows in one shot and the init callback runs for the whole batch — aggregate initialization is naturally batched |
| restore lands in place | key deserialization probes through the KeyTable's restore gate; a restored key and its runtime probe land in the same row, same bucket |
| dead-key reclaim | `advance()` reclaims unreferenced key rows at batch boundaries only; snapshot reclaims first, dead keys never cross a checkpoint |
| one name one instance | handles register by name; a second get returns the same instance; same name with a different type CHECK-fails |

Keys surface as `RowContainerStateKey`: a row-pointer view+hash/keyGroup cached at construction. Key column types support fixed-width scalars and varchar/varbinary; complex types must first be reduced to scalar columns.

## Choosing a state handle

| Handle | descriptor | Value shape | Fits |
|---|---|---|---|
| `AggregatingState<K,N>` | accumulators+init/merge callbacks | RowContainer row, accumulator layout (isomorphic to HashAggregation rows) | aggregation: function updates slots in place |
| `ValueState<K,N,V>` | `TypeSerializer<V>` | single value | per-key scalar (latest value, marker) |
| `ListState<K,N,T>` | `TypeSerializer<T>` | vector<T> | per-key append-only sequence |
| `MapState<K,N,UK,UV>` | key/value serializers | map<UK,UV> | per-key sub-index (join, rank) |

Namespace type `N`: `VoidNamespace` when there is no partitioning semantics; a custom `Namespace` when one key spans logical partitions (windows).

Aggregating callback contract:

- `initRows(rows, numRows)`: called once per materialized miss batch; the operator side wraps `Aggregate::initializeNewGroups`;
- `mergeRow(row, columns)`: on restore, merges a single row's intermediate columns into the freshly constructed row; the operator side wraps `addSingleGroupIntermediateResults`;
- the state layer depends on no Aggregate facility — row construction and checkpoint round-trips go entirely through the accumulators array and the two callbacks;
- descriptor closures capture the operator's raw pointers; captured objects must outlive every handle created from the descriptor.

## Step-by-step implementation

### 1 Plan node (mirrored across three repos)

- velox: add the node class to `StatefulPlanNode.h` (model on `GroupAggregationNode`: handler child node+`KeyedStateSpec`); the serialize/create/registerSerDe trio.
- velox4j: same-named same-field mirror class under `plan/`+`stateful/KeyedStateSpec`; the serde registration name must match C++ exactly.
- `KeyedStateSpec` carries only key channels and types — no runtime backend is built at this layer: the key-group range lives only in task parameters, and the operator's `initializeStateBackend` builds the backend.

### 2 Planner dispatch

`StatefulPlanner#transformStatefulOperators` dispatches on the inner node type; a new operator adds one branch: recursively build targets→`EmptyOperator` placeholder→construct the operator. Pure streaming operators have no batch body; all processing lives on the streaming path.

### 3 Operator lifecycle

| Hook | Responsibility | Discipline |
|---|---|---|
| constructor | hold the node pointer | pin plan constraints as CHECKs (output schema, unsupported semantics) |
| `initialize()` | stateless facilities (aggregate functions via `makeAggregateInfos`) | never touch state |
| `initializeStateBackend()` | build the keyed backend (five steps below) | keyed-operator-only hook |
| `addInput()` | main path (seven-step pattern below) | event dispatch+business logic+changelog |
| `close()` | reset handles/backend/selector, then call the base class | release in reverse order |

Five steps of `initializeStateBackend`:

1. `createKeyedStateBackend<K>(*stateBackend, spec, memoryPool())` builds the backend — the sole creation entry; maxParallelism and the key-group range are read from task parameters inside the entry;
2. `KeySelector(backend->keyIndex(), spec.keyChannels())` binds the key table;
3. construct the descriptor, `getOrCreateXxxState<N>()` for the handle;
4. AggregatingState wiring: `setAllocator`+`setOffsets(valueRows->columnAt(i)…)` — strictly before the first `rows()` and before restore (both miss materialization and restore build rows);
5. call the base-class implementation to forward downstream.

The creation entry is defined in `state/HeapKeyedStateBackend.h` as a free template function: the key type K (a StateKey subclass) can only be named by the operator, and virtual functions cannot be templates, so the entry cannot be a virtual member of `StateBackend` — the pre-generic factory on the base class remains for unmigrated operators. The entry dispatches on the task's declared backend type: a declared type with no engine (currently ROCKSDB) fails loud with `VELOX_UNSUPPORTED` at operator initialization, never silently falling back to heap.

Seven-step `addInput` pattern (`GroupAggregator` is the reference):

1. cast to `StreamRecord` and validate rowKind — unsupported kinds must fail loud, never drop silently;
2. `keySelector_->probe(input)`: one probe yields per-row keys, distinctKeys, and newGroups;
3. `state_->rows(distinctKeys, ns, outRows)` resolves state rows in batch (misses trigger the init callback);
4. business logic updates state rows in place (`addRawInput` and friends);
5. changelog planning: new key emits +I; changed value emits (-U+)+U (-U only when the plan demands update-before); unchanged emits nothing;
6. assemble the `StreamRecord` (key columns extracted from keyRowContainer by emit index, value columns pick the before/after mirror per kind)→`pushOutput`;
7. at the batch boundary, `keyedBackend_->advance()`.

Watermarks cascade by default; only event-time operators (windowing) override `processWatermark`.

### 4 gluten wiring

- Shadow-override the ExecNode inside the Flink package: `translateToPlanInternal` builds the velox4j node tree wrapped in `StatefulPlanNode`; the operator side is `GlutenOneInputOperator`.
- Iron rule: **the Flink-side transformation stays non-keyed**. Keys belong to velox (`KeyedStateSpec` feeds the C++ backend) and routing is decided by C++ StreamPartition; declaring a Flink key selector makes the runtime recompute key groups with the Flink hash and assert against the KeyGroupRange, which conflicts with velox routing at parallelism > 1.

### 5 Checkpoint

- The operator exposes its backend through the `keyedStateBackend()` accessor; byte persistence for snapshot and restore is driven by task-side checkpoint orchestration.
- snapshot layout: header (maxParallelism, key-group range, flags)→schema table (key schema+per-state namespace/value schemas)→per-state entries in ascending key-group order→CRC32 tail.
- restore validation: CRC; maxParallelism must be equal (it defines the key-group space); the schema table is cross-checked against registered states one by one; streams intersecting this backend's range are taken, out-of-range entries skipped — rescale-sharded restore falls out naturally.
- Restore order is the reverse of Flink: register states first, restore second. Each handle owns its own table; restore dispatches straight to registered handles, no backend-level registry needed.

### 6 Testing

Model on `velox/experimental/stateful/tests/GroupAggregatorTest.cpp`:

- fixture: `OperatorTestBase`; register the needed aggregate functions; `HashMapStateBackend`+`KeyedStateBackendParameters` act as the task-level backend;
- downstream is a collecting `StatefulOperator`; construct operators in production lifecycle order: `initialize()`→`initializeStateBackend()`;
- three input shapes: appendOnly (no rowKind column), explicit INSERT rowKind, mixed kinds;
- persistence: `snapshot()`→fresh operator `restore()`→keep feeding and assert equivalence; rescale restores a partial range with different key-group bounds;
- backend facility unit tests live in `StateBackendTest` (including creation-entry dispatch), `CheckpointFormatTest`, `StateKeyTest`, `KeySelectorTest`; the checkpoint chain walk (full chain even without a legacy handler) is covered by `StatefulOperatorCheckpointTest`.

## Pitfalls

| Symptom | Cause | Avoidance |
|---|---|---|
| Flink asserts key-group mismatch at parallelism > 1 | the Flink-side transformation was declared keyed | keep the transformation non-keyed |
| accumulators corrupted or crash | setAllocator/setOffsets ran after the first `rows()` or restore | wire immediately after creating the handle |
| handle destructor steps on freed memory | descriptor closures hold the operator's raw pointer, operator died first | close() resets handles first; captured objects outlive handles |
| `VELOX_NYI: … not available on the heap backend` | went through the old state API (base-class factories/`StreamOperatorStateHandler`) | new operators always use the `HeapKeyedStateBackend` template methods (typed API) |
| `VELOX_UNSUPPORTED: The RocksDB keyed state backend is not implemented` at initialization | the task backend declaration names ROCKSDB, which the typed creation entry has no engine for | only HEAP is available today — keep types with no engine out of the backend declaration |
| restore rejected: maxParallelism mismatch | changing maxParallelism changes the key-group space | fix it for the whole lifetime |
| restore rejected: schema or state mismatch | restore before registration, or schema drift | register before restore; schema evolution needs versioning |
| key columns with array/map/row error out | key equality supports only fixed-width scalars+varchar/varbinary | use scalar key columns or reduce first |
| dead key rows cross a checkpoint | `advance()` not called at batch boundaries | call it every batch end; snapshot reclaims first |
