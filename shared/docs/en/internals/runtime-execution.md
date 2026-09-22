# Runtime execution: the per-record data loop

What happens after the JobGraph ships: how gluten operators are organized inside Flink's task threads, how `open()` brings the C++ side up, how each record travels Java -> Arrow -> queue -> Velox chain -> back, and how the side paths (watermarks, processing-time timers, checkpoints, shutdown) stay thread-safe. The C++ internals of the chain itself are the [stateful operators](stateful-operator.md) page.

```text
JobGraph generation
 |  one chain slice per gluten operator; both ends gluten ->
 |  Arrow (StatefulRecord) pass-through, otherwise RowData
 v
TaskManager: operator open()  [once]
 |  1 bridges        2 session resource      3 BlockingQueue (shared via JNI)
 |  4 mock ExternalStream source + real plan -> JSON -> execute -> task handle
 |  5 addSplit binds the queue; noMoreSplits seals it
 |  6 register native callback target
 v
+---------------- per record / per trigger ----------------+
| Flink upstream -- RowData --> processElement              |
|   1 inputBridge: 1 row -> 1-row Arrow RowVector,          |
|     trailing $row_kind TINYINT column appended            |
|   2 inputQueue.put  --shared BlockingQueue-->             |
|        C++ TableScan(ExternalStream)::next pulls it       |
|        StatefulTask::next advances the chain one round;   |
|        results land in the task's pendings                 |
|   3 processElementInternal -> drainTaskOutput loop:       |
|        task.advance() -> statefulGet()                    |
|        Watermark -> emitWatermark | Status -> emitStatus  |
|        Record -> outputBridge -> RowData per row,         |
|                   or StatefulRecord direct when downstream |
|                   is gluten (Arrow not dismantled)        |
|  BLOCKED = nothing yet, wait for next trigger;            |
|  FINISHED = stream ended                                   |
+-----------------------------------------------------------+
side paths: watermark in: processWatermark -> task.notifyWatermark,
            then drain. timer out: C++ -> NativeCallbackBridge ->
            Java mailbox -> drainTaskOutput (never a new thread).
            checkpoint: barrier -> snapshotState -> synchronous
            task.snapshotState. restore: initializeState.
close(): unbind callbacks -> close task -> noMoreInput ->
         close queue -> unregister session -> close resources
```

| Stage | Entry point | Question answered |
|---|---|---|
| 1 JobGraph | `OffloadedJobGraphGenerator` (gluten-flink runtime) | chain slicing and the Arrow pass-through decision |
| 2 Open | `GlutenOneInputOperator#initSession` / `#open` | how the C++ task is created |
| 3 Uplink | `GlutenOneInputOperator#processElement` + `FlinkRowToVLVectorConvertor#fromRowData` | how one row becomes an Arrow batch in the queue |
| 4 Pull | `ExternalStreamDataSource#next` (velox4j) + `BlockingQueue#read` | how C++ takes data, and how "nothing yet" is expressed |
| 5 Drive loop | `GlutenOneInputOperator#drainTaskOutput` -> JNI `advance0` -> `StatefulTask#next` | how results return and who drives the next round |
| 6 Watermarks & timers | `#processWatermark`, `#onProcessingTime`, mailbox | how the side signals cross without races |
| 7 Checkpoint | `#snapshotState` / `#initializeState` / `#notifyCheckpointComplete` | how state stays consistent |
| 8 Close | `GlutenOneInputOperator#close` | teardown order and why it matters |

## Stage 1: chain slicing and the pass-through decision

Each chain slice may hold exactly one gluten operator — each owns its own StatefulTask; two gluten operators never share a Task thread. For each operator the generator asks: is the upstream slice gluten too? the downstream? Both gluten -> the middle carries `StatefulRecord` (the Arrow vector passes through whole; no Arrow->RowData->Arrow round trip — a key throughput decision). Either end native -> that side falls back to RowData. The generator clones the planner's operator with the decided input/output classes and installs it via `GlutenOneInputOperatorFactory` — mandatory, because plain `setStreamOperator` would wrap it in a factory that skips the mailbox binding stage 6 depends on.

## Stage 2: open() — seven steps

`initSession` runs once per task lifetime: (1) pick the input/output bridges per the declared classes; (2) session resource (velox4j Session + Arrow allocator); (3) create the BlockingQueue in Java — C++ later retrieves the same object by id through the ObjectStore; (4) build the mock ExternalStream input plan and serialize+execute the query ([plan serialization](plan-serde.md)); (5) `addSplit` binds the queue to the scan node, `noMoreSplits` seals it; (6) `bindNativeCallbackTarget` registers the timer callback entry; (7) done — the handle named `task` is the interface for everything that follows.

## Stage 3: uplink, one row at a time

`processElement` per record: convert, put, then immediately `processElementInternal()` — one record pushes one round ("data arrives, give it a pull"). Conversion (`fromRowData`) builds a **1-row** RowVector per RowData: no Java-side batching (the vectorized batching happens inside Velox; connectors like nexmark arrive whole-batch anyway). A trailing `$row_kind` TINYINT column carries Flink's row kind (+I/-D/-U mirrors) into Velox; the column name string is a contract shared with the C++ side, which strips it on the way in and re-attaches it on the way out. Ownership: only vectors this operator created are closed here — pass-through vectors belong to the upstream (Arrow memory is reference-counted; double-free is the alternative).

## Stage 4: the C++ pull, and "nothing yet"

`ExternalStreamDataSource#next` reads from the queue the split bound. `BlockingQueue#read` semantics: data -> pop and return; empty and FINISHED -> `nullptr` (graceful stream end, triggers the finish cascade); empty and still open -> `nullopt` — "nothing yet". The async promise-wait that upstream velox4j had at this point is disabled in this fork, which makes the whole system **purely pull-based**: C++ never blocks waiting for data; control returns to Java and the next trigger retries. That one disabled block is the load-bearing fact of the entire execution model.

## Stage 5: the drive loop

Each trigger runs `drainTaskOutput`: call `task.advance()` (JNI `advance0` -> `StatefulTask::next` — clear any un-taken output first, then advance the whole chain one round). Three states: AVAILABLE -> `statefulGet()` fetches the element as a Java `StatefulElement`, dispatched by kind (watermark / watermark status / record) and **closed explicitly** afterwards — it holds native handles. BLOCKED or FINISHED -> break, wait for the next trigger. Output conversion (`toRowData`) fans a multi-row vector out row by row, honoring `$row_kind`. Two exceptions: print-sink output never crosses this bridge (C++ prints directly; see [plan serialization](plan-serde.md)); a gluten downstream receives the `StatefulRecord` whole.

## Stage 6: watermarks and timers via the mailbox

Downstream watermarks: `processWatermark` -> `task.notifyWatermark` (window triggering happens entirely in C++), then the usual drain. Upstream (timer) direction: a C++ processing-time timer fires the Java callback, which does exactly one thing — schedule a `drainTaskOutput` into the Flink mailbox. C++ never opens a thread into Java; everything flows back through the mailbox, serialized with record processing and barrier processing. The `closing` flag checked at each entry point keeps stale queued callbacks from resurrecting a closed operator.

## Stage 7: checkpoint

On barrier alignment Flink calls `snapshotState` -> synchronous `task.snapshotState` (JNI) -> the C++ chain snapshots into the Flink state store ([stateful operators](stateful-operator.md) for what exactly is snapshotted, and the RocksDB pass-through that skips serialization). Restore: `initializeState` runs before `open()` on restart — it lazily creates the session if the task handle does not exist yet. `notifyCheckpointComplete`/`Aborted` forward for commit-style sinks. Non-RocksDB backends restore native state from the store; RocksDB re-attaches to the live instance.

## Stage 8: close, in reverse dependency order

`closing = true` first (blocks queued callbacks), then: unbind the native callback target (C++ stops calling Java) -> close the task (C++ chain destroyed) -> `noMoreInput` on the queue (state FINISHED so C++ reads a graceful end — before closing the queue, or C++ reads a closed queue) -> close the queue -> unregister the session context -> close the session resource (allocator) -> `super.close()`. Each step exists so the next one cannot race it.

## Adding a new runtime operator

Usually inheritance is enough: extend `GlutenOneInputOperator` (or `GlutenTwoInputOperator`), pass the planner-built plan tree, declare `RowData.class` or `StatefulRecord.class` per the desired pass-through — the JobGraph generator's clone decides the actual wiring. Subclass for special lifecycles only (e.g. WindowAggOperator reflecting RocksDB handles at initializeState; file sinks managing their own commits). When overriding data-path methods keep the three-part shape: convert to Arrow -> put -> `processElementInternal`. New input/output types extend the respective bridge factory; operators outside the source/one-input/two-input shapes add a branch in `OffloadedJobGraphGenerator`.

## Pitfalls

| Symptom | Cause | Fix |
|---|---|---|
| Loop exits immediately, no output | BLOCKED is "nothing yet", not an error | wait for the next trigger; data arrival and timers both re-drive |
| Native memory growth | fetched `StatefulElement` not closed | close it in a finally — it holds native handles |
| Double-free / corrupted Arrow buffers | closing pass-through vectors you do not own | only the creator closes; check the node-id ownership test |
| Timer or watermark output never arrives | forgot the drain after the side path | every entry point ends in `processElementInternal` |
| Callbacks hitting a closed operator | stale mailbox entries | the `closing` checks are load-bearing; keep them in overrides |
| C++ reads a closed queue | teardown order wrong | `noMoreInput` strictly before queue close |
