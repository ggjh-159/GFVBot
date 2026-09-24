# Stateful operators: the streaming runtime inside Velox

The streaming runtime under `velox/experimental/stateful/`: how it reshapes Velox's batch-born execution for unbounded streams, and the API surface a new stateful operator implements. Read [runtime execution](runtime-execution.md) first for how Java drives this side; this page is the C++ interior.

Three design decisions carry everything:

1. **Pull-based single thread**: `StatefulTask` extends `exec::Task` pinned to `ExecutionMode::kSerial` — no driver threads; Java advances it one round per record or timer callback.
2. **Composition over rewrites**: `StatefulOperator` is a shell holding a native `exec::Operator` (stateless FilterProject/TableScan reused as-is); operators with stateful semantics subclass the shell instead.
3. **One event model**: data records, watermarks, and idle markers are all `StreamElement`s on the same channel.

```text
+---------------- StatefulTask (exec::Task, kSerial) ----------------+
|  operatorChain_ = StatefulOperator chain                            |
|                                                                     |
|   +------------------ StatefulOperator (shell) ----------------+    |
|   | operator_     embedded native exec::Operator               |    |
|   |               (FilterProject / TableScan / HashProbe ...)  |    |
|   | targets_      downstream shells                            |    |
|   | stateHandler_ state + timer handle (stateful operators)    |    |
|   +-------------------------------------------------------------+    |
|                                                                     |
|  advance: chain head advanceWithFuture                              |
|    -> operator_->getOutput() pulls the native operator             |
|       -> pushOutput: result -> targets[i]->addInput + advance      |
|          (recursive cascade; no intermediate queues; the chain     |
|           tail feeds the task's pendings_, awaiting Java's get)    |
|                                                                     |
|  events: StreamRecord / Watermark / WatermarkStatus, same channel  |
+---------------------------------------------------------------------+
  side paths: watermarks travel processWatermark along the chain
  (multi-input merges to the minimum before emitting); timers fire
  Triggerable#onEventTime/onProcessingTime (processing-time callbacks
  go back through the Java mailbox); checkpoints walk the chain via
  snapshotState into the state backend (heap snapshots explicitly;
  RocksDB reads/writes Flink's live instance directly)
```

| Stage | Entry point | Question answered |
|---|---|---|
| 1 Event model | `StreamElement` hierarchy (`experimental/stateful/StreamElement.h`) | what flows on the chain |
| 2 The task | `StatefulTask::create` / `#init` / `#initStateBackend` | how the pull-based task is built and the backend injected |
| 3 The shell | `StatefulOperator` (`StatefulOperator.h/.cpp`) | how native operators are wrapped and the chain cascades |
| 4 Planning | `StatefulPlanner::plan` / `#transformStatefulOperators` | where a new operator plugs into assembly |
| 5 State & timers | `StreamOperatorStateHandler` (`state/`) | the state and timer API operators use |
| 6 Checkpoint | `StatefulOperator#snapshotState` + `WindowAggOperator` (gluten-flink runtime) | snapshot alignment and the RocksDB pass-through |
| 7 Exemplar | `WindowAggregator` (`WindowAggregator.h`) | all of the above assembled into one operator |

## Stage 1: one event model

`StreamRecord` (payload: a `RowVectorPtr` — the chain stays vectorized end to end), `Watermark` (event time advanced to t), `WatermarkStatus` (this input is idle; downstream should not wait for its watermark). One element type means one addInput/output path and one cascade implementation; data and control messages do not compete for dedicated channels.

## Stage 2: the task

`StatefulTask::create` registers in the task pool; the constructor's whole body is the `kSerial` argument. `init` builds and initializes the chain. `initStateBackend` takes parameters from the Java side: RocksDB parameters (native handles, see stage 6) build a `RocksDBStateBackend`; otherwise a heap `HashMapStateBackend`. The backend is injected into every operator on the chain.

## Stage 3: the shell and the cascade

`StatefulOperator` owns the embedded native operator, the downstream target list, and (for stateful operators) a `stateHandler_`. The base-class virtuals form the streaming lifecycle API — `initialize`, `isFinished`, `addInput`, `advance`, `advanceWithFuture`, `close`, `finish`, `processWatermark`, `processWatermarkStatus`, `checkWatermarkStatus`, `initializeState` — and the default implementations just delegate to the embedded operator and recurse into targets, so a purely stateless transform plugs in with zero code.

The load-bearing method is `pushOutput`: a non-tail operator's output goes directly to `targets_[i]->addInput` + `advance` (recursion); the tail hands elements to the task's pendings_. One advance rolls data to the tail or parks it inside an operator (a window accumulating) — no queues in between. `finish` drains: noMoreInput, then loop getOutput until dry — window operators flush their last outputs here. Multi-input watermark handling merges per-input watermarks (combined minimum) and emits status transitions on idle changes, mirroring Flink's combined watermark semantics.

## Stage 4: assembly dispatch

`StatefulPlanner#transformStatefulOperators` unwraps each `StatefulPlanNode` and dispatches on the inner node type: stateful-specific nodes get custom transforms (which construct the StatefulOperator subclass plus its key selector and state parameters); everything else goes through the generic wrapper ([plan serialization](plan-serde.md)). **A new operator's assembly hook is a branch in this ladder.**

## Stage 5: state and timers

One `StreamOperatorStateHandler` per operator, deliberately mirroring Flink's `StreamOperatorStateHandler` shape. All state values are `RowVectorPtr` — state is vectors, like everything else.

| API | Shape | Typical use |
|---|---|---|
| `getValueState` | `ValueState<key, window, RowVectorPtr>` | window aggregation accumulators |
| `getMapState` / `getListState` | map/list variants | per-key collections |
| `setCurrentKey` | before any state access | Flink keyed-state discipline, one-to-one |
| `createTimerService(triggerable)` | returns `InternalTimerService` | timers whose callbacks land in the operator itself |
| `snapshotState(checkpointId)` | backend snapshot | stage 6 |

`InternalTimerService` offers `registerEventTimeTimer` / `registerProcessingTimeTimer` / `delete...` / `advanceWatermark` — event-time timers fire on watermark advance; processing-time callbacks route back through Java's mailbox ([runtime execution](runtime-execution.md)).

## Stage 6: checkpoint and the RocksDB pass-through

`StatefulOperator#snapshotState` recurses along the chain: the embedded operator's own snapshot plus the state handler's snapshot plus any `Snapshotable` embedded operator; heap backends produce explicit snapshot records (strings) collected back into the Flink state store. `restoreState` and `notifyCheckpointComplete` (sink commits) are symmetric.

The RocksDB path is the interesting one: Velox does not run its own RocksDB — it uses **Flink's live instance**. On the Java side, `WindowAggOperator#initializeState` reflects the native handles out of Flink's `RocksDBKeyedStateBackend` (the db object, read/write options, the column family handle), packs them with key/accumulator type info into `RocksDBKeyedStateBackendParameters`, and passes them through `task.initializeState`. The C++ backend then reads and writes the same db. One RocksDB holds both Flink-native and Velox state, and Flink's barrier keeps them consistent; non-RocksDB backends take the explicit-snapshot path above.

## Stage 7: the exemplar

`WindowAggregator` is the template for everything: dual inheritance (`StatefulOperator` + `Triggerable<int64_t,int64_t>`), overrides only the lifecycle hooks it needs (`initializeState` takes the ValueState and the timer service; `addInput` sets the current key and registers timers; `onEventTime`/`onProcessingTime` converge on the flush; output goes through `pushOutput`), and the two-phase local/global aggregation operators live inside the shell.

## Adding a new stateful operator

1. **Plan node** (velox): node class in `StatefulPlanNode.h` modeled on `GroupAggregationNode`, carrying all static parameters; `serialize()` + `static create`; register in `StatefulPlanNode::registerSerDe()`.
2. **Java mirror** (velox4j): same-named same-field PlanNode class under `plan/`, registered in `ISerializableRegistry` — the name must match exactly ([plan serialization](plan-serde.md)).
3. **Operator** (velox): inherit `StatefulOperator` (+ `Triggerable` for timers), override the hooks per stage 7's pattern; a key-carrying operator models itself on `StreamKeyedOperator`.
4. **Factory** (velox): the `transformStatefulOperators` branch constructing the operator (stage 4).
5. **Planner side** (gluten): the ExecNode override building the node ([plan rewrite](plan-rewrite.md)).
6. **Runtime side** (gluten): usually plain `GlutenOneInputOperator` already suffices; subclass only for special lifecycles.

Must-implement API summary: the node's serialize/create/registerSerDe trio; the operator's `initialize`/`addInput`/`advance` (plus `initializeState` when state is involved); the factory branch; the Java-side serde registration. Optional by semantics: `processWatermark`, `checkWatermarkStatus`, `numInputs`, `needsFinishDrain`.

## Pitfalls

| Symptom | Cause | Fix |
|---|---|---|
| State access misbehaves | no `setCurrentKey` before reading/writing | set the current key first, always |
| Downstream never initializes | an overridden `initializeState` forgot the recursion | recurse into targets like the default does |
| Output never reaches Java | produced outside `pushOutput` | everything exits through pushOutput; the tail feeds pendings |
| Event-time timers never fire | they advance with watermarks only | check the watermark actually reaches the operator (idle inputs!) |
| State missing after restore | non-RocksDB backend with no explicit snapshot path | heap backends rely on the snapshot records, not the live instance |
| Last window's output lost | flush happens in `finish` | respect `needsFinishDrain` and the drain loop |
