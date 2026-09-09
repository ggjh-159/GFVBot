# Verification workflow

Every GFV change — an expression, an operator, an aggregate, or a performance tweak — is verified through the same loop: rebuild the jars, restart the cluster, submit a nexmark query, read the result. This page covers the loop end to end; the build step itself is owned by the flink-velox-build skill.

Prerequisites: a workspace initialized per the README walkthrough (repos cloned, flink and nexmark installed via env-init, `.gfvbot/env.json` present). Paths below come from the env archive: the flink installation is `stack.flink.path` and the nexmark home (holding `bin/run_query.sh` and the `queries/` directory) is `stack.nexmark.home`.

## The loop

- Build: run the flink-velox-build skill's `bin/compile.sh`. It builds velox4j (native .so included) and gluten-flink, then copies the four GFV jars plus their runtime dependencies into the flink installation's `lib/` and pins the cluster JDK (`env.java.home`) to the build JDK.
- Restart: stop and start the cluster from the flink installation's `bin/`. TaskManager daemons load everything from `lib/` at startup; a running daemon keeps the old jars and the already-loaded native library, so results collected without a restart reflect stale code.
- Submit: run nexmark's `run_query.sh` with the flink home exported. The first argument is the query category (`oa` is the default streaming set; `cep` is a separate set), the second the query id or `all`.
- Observe: the submitting terminal streams job progress and, once the job reaches `FINISHED`, prints the benchmark metrics (events processed, elapsed time, throughput). The flink web UI (port 8081) shows per-operator state and backpressure while the job runs.
- Compare: for performance work, rerun the same query on the baseline build and diff the metrics; keep events-per-run fixed so the numbers are comparable.

```bash
bash <skill-dir>/bin/compile.sh
<flink-home>/bin/stop-cluster.sh && <flink-home>/bin/start-cluster.sh
FLINK_HOME=<flink-home> <nexmark-home>/bin/run_query.sh oa q0
```

## Failure modes worth knowing

- Stale jar: after the build, check the jars in `lib/` carry fresh timestamps before starting the cluster; a stale jar is indistinguishable from a code bug at runtime.
- Native library drift: any C++ change requires the full native build (never skip it) and a cluster restart; JNI libraries already loaded in a running daemon are not swapped by jar replacement.
- UnsupportedClassVersionError in the cluster log: the daemon is running an older JDK than the build; the compile step pins `env.java.home` for exactly this, so starting the cluster through the installation's own scripts picks the right JDK.
- Blackhole sinks: nexmark queries write to blackhole connectors, so correctness signals are row counts and job metrics, not output tables; pick the query per the nexmark query reference.
