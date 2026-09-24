---
name: flink-velox-build
description: Compile velox4j (native .so included) and gluten-flink in a GFV workspace via the workspace compile script, and deploy the jars into the local Flink installation.
---

# flink-velox-build

## Purpose

Build the core artifacts of the GFV stack in the target workspace:

- velox4j, including its native C++ library
- gluten-flink (planner / loader / runtime)

and place the resulting jars where the local Flink installation loads them.

## Workspace layout this skill assumes

- Source repos live under `<workspace>/repos/` (velox, velox4j, gluten, flink), laid down by `gfvbot clone`.
- Beyond the package-manager dependencies (`gfvbot env`), the build links Velox's source-built C++ libraries (boost, the folly chain, protobuf, arrow, ...) from `/usr/local`; they are installed by ticking `source-deps` in the `gfvbot env-init` list, driven by the official setup script in the velox checkout. Tick it once after `gfvbot clone` on a fresh machine.
- The workspace env archive `.gfvbot/env.json` (produced by `gfvbot env`, extended by `gfvbot clone`) is the single source of paths: repo locations, the flink installation, JAVA_HOME, and the nexmark jar. Do not hardcode paths and do not maintain a hand-written config alongside it.
- The compile entry is this skill's `bin/compile.sh`. It locates `.gfvbot/env.json` by walking upward from its own location, builds velox4j, installs it into the local Maven repository, builds gluten-flink against it, and copies the resulting jars into the flink installation's `lib/`.

## Usage

```bash
bash bin/compile.sh > tmp/<task-name>/logs/cmd-outputs/build-all.log 2>&1
tail -5 tmp/<task-name>/logs/cmd-outputs/build-all.log
```

Run `bin/compile.sh` relative to this skill's directory (or invoke it by absolute path from anywhere under the workspace). Check the exit code and the log tail; on failure, grep the log for the first error, and read the existing log before re-running — a re-run is worth it only when the inputs changed.

## Discipline

- Never skip the C++ build. Flags like `-Dskip.cpp.build` or force-C++ shortcuts produce a Java-only jar whose bundled .so drifts out of sync with the C++ sources, and the drift surfaces later as wrong results rather than a build error. If the full build is too slow, say so and ask — do not silently skip.
- Temporary artifacts stay inside the project directory, never in `/tmp` — the user only looks at artifacts inside the project directory: with a task context, build logs land in `tmp/<task-name>/logs/cmd-outputs/build-<description>.log`; without one, `<workspace>/.gfvbot/tmp/build-<description>.log`. Inspect with tail/grep; a full compile streams tens of thousands of lines, and pulling that into context wastes the window.
- After the build, confirm the fresh jars actually landed in `$FLINK_HOME/lib/` before starting a cluster or a verification run. A stale jar is indistinguishable from a code bug at runtime.
- If the working trees carry uncommitted fixes (for example nexmark-side timestamp or sink patches), confirm every fix is included in the artifacts before verifying against them — a rebuilt .so that misses one pending fix invalidates the comparison.
- Incremental rebuilds are fine when only Java sources changed; C++ changes require the native build to run.
