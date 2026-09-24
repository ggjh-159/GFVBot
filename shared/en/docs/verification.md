# Verification workflow

Every GFV change — an expression, an operator, an aggregate, or a performance tweak — is verified through the same loop: rebuild the jars, restart the cluster, submit a nexmark query, read the result. This page covers the loop end to end; the build step itself is owned by the flink-velox-build skill.

Prerequisites: a workspace initialized per the README walkthrough (repos cloned, flink and nexmark installed via env-init, `.gfvbot/env.json` present). Paths below come from the env archive: the flink installation is `stack.flink.path` and the nexmark home (holding `bin/run_query.sh` and the `queries/` directory) is `stack.nexmark.home`.

## The loop

```text
        +--------+
        | build  |  compile.sh -> fresh jars land in the flink lib/
        +--------+
            v
        +---------+
        | restart |  stop/start cluster -> daemons load the new jars
        +---------+
            v
        +--------+
        | submit |  run_query.sh oa qN -> nexmark job on the cluster
        +--------+
            v
        +--------+
        | watch  |  terminal streams progress; web UI shows operators
        +--------+
            v
        +---------+
        | compare |  same query, fixed events: baseline vs change
        +---------+
            --- repeat after every change ---
```

| Step | Command | Confirm |
|---|---|---|
| Build | `bash <skill-dir>/bin/compile.sh` | jars in the flink `lib/` carry fresh timestamps; the GFV jars plus runtime dependencies landed |
| Restart | `<flink-home>/bin/stop-cluster.sh && <flink-home>/bin/start-cluster.sh` | TaskManagers restarted after the jars landed, not before |
| Submit | `FLINK_HOME=<flink-home> <nexmark-home>/bin/run_query.sh oa q0` | job reaches RUNNING, then FINISHED |
| Watch | submitting terminal; web UI on port 8081 | benchmark metrics print after FINISHED (events processed, elapsed, throughput); operator state and backpressure visible while running |
| Compare | rerun the same query on the baseline build | events-per-run kept fixed so the numbers are comparable |

The first query argument is the category (`oa` is the default streaming set; `cep` is a separate set), the second the query id or `all`. Query selection goes through the nexmark query reference.

## Failure modes

| Symptom | Cause | Action |
|---|---|---|
| Results do not reflect the code change | running daemons keep the old jars — a stale jar is indistinguishable from a code bug | check jar timestamps in `lib/` before starting; restart; resubmit |
| A C++ change had no effect | the native build was skipped, or the already-loaded JNI library was never swapped | never skip the native build; restart the cluster after every rebuild |
| `UnsupportedClassVersionError` in the cluster log | the daemon runs an older JDK than the build | the compile step pins `env.java.home`; start the cluster through the installation's own scripts |
| No output table to compare against | nexmark queries write to blackhole connectors | verify via row counts and job metrics; pick queries per the nexmark query reference |
