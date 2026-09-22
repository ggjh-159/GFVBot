# GFVBot

[English](README.md) | [中文](README.zh.md)

GFVBot is the AI foundation for GFV (the gluten-flink-velox integration track). Content is organized as plugins: one plugin per development scenario, carrying that scenario's workflow, agents, skills, and reference docs. Installed into a target project, a plugin runs in that project's AI agent environment.

> Status: the framework (installer, adapters, tests) is complete; plugin content (skills / agents / docs) is still being filled in.

## Repository layout

| Path | Responsibility |
|---|---|
| `plugins/` | Scenario plugins, one directory per scenario: each carries its development workflow (workflow.md) and agent definitions, and declares the shared skills and docs it needs |
| `shared/` | Knowledge assets shared across plugins: skills (build, unit testing, doc retrieval, code review), docs (architecture, verification, nexmark queries, expression reference, internals deep-dives), templates |
| `installer/` | Installer engine and AI agent adapters (claude / opencode / codex / dsh): installs plugins and shared content into a target project |
| `tests/` | Tests and guardrails for the content assets: L1 static validation (manifest consistency, en/zh mirroring, dependency rules) and installer e2e smoke tests |

## Plugins

Each plugin targets one development scenario; install the one matching the goal at hand:

### `stateless-expression-development` — stateless expression development

For scalar functions and expressions in SQL: string, datetime, numeric, and other functions that are **computed row by row, depend on no other rows, and keep no intermediate state** (e.g. `SPLIT_INDEX`, `EXTRACT`). Developing a function in this scenario covers three parts: implementing the C++ vectorized version in velox, mapping the Flink function name to the velox function name, and wiring the three layers so the SQL function call is pushed down to velox.

### `stateful-operator-development` — stateful operator development

For window aggregation, streaming joins, TopN, deduplication, and other operators that **maintain state across rows**. Development here involves rewriting the Flink ExecNode into a velox plan node on the planner side, implementing the operator lifecycle on the velox side — state access, watermarks and timers, checkpoint alignment — and configuring nexmark queries for behavior verification.

### `aggregate-function-development` — aggregate function development

For SUM/COUNT/AVG and custom aggregates: functions that collapse many rows into a single value. The core of this scenario is implementing velox's Aggregate interface, completing the accumulate (accumulation) / merge (shard merge) / finalize (final output) chain, and integrating with batch and window aggregation execution.

### `performance-optimization` — performance optimization

For cases where the feature is correct but performance falls short. The workflow is a loop: run the nexmark benchmark against native Flink to quantify the gap, profile to locate hotspots (on both the C++ and JVM sides), apply the fix, regression-verify, and iterate until the target is met.

## Six steps from a bare machine to AI-assisted coding

Supported OSes: openEuler, CentOS 7/9, Ubuntu/Debian. Run the steps in order — each one builds on the previous, and together they take you from an empty machine to a working GFV workspace where the AI agent does the coding with you. Every step resumes: detected dependencies are skipped, existing repos and configuration are left untouched, so after an interruption just rerun the same command.

### Step 1: install the gfvbot CLI

```bash
bash installer/setup.sh
```

Installs the `gfvbot` command-line tool. Done when `gfvbot help` prints the command list.

### Step 2: install a scenario plugin

```bash
cd /path/to/gfv      # the target project root; run all further commands from here
gfvbot install stateful-operator-development
```

Installs the plugin into the current project — its skills, its docs, and its development workflow. Without `--tool` it asks for the AI agent interactively; add `--tool claude` to skip the question. Selectable today: `claude` (Claude Code) and `opencode`; the `codex` and `dsh` (DeepSeek Harness) adapters are ready and open once verification environments are available.

Done when `gfvbot list` shows the plugin as installed.

### Step 3: clone the GFV source repos

```bash
gfvbot clone
```

Clones the four source repos under `repos/`, giving every machine the same workspace layout (installs git when missing). Defaults:

| Repo | Upstream | Branch |
|---|---|---|
| velox | bigo-sg | `gluten-20260829` |
| velox4j | bigo-sg | `gluten-20260829` |
| gluten | apache | `main` |
| flink | apache | `release-1.19` |

Useful flags: `--fork <user>` clones velox/velox4j/gluten from your forks (same branches; flink always official), `--shallow` = `--depth 1`, or name repos to clone a subset (`gfvbot clone velox velox4j`). Existing repos are skipped; after cloning, version control is plain git.

### Step 4: scan the environment and fill the gaps

```bash
gfvbot env          # scan dependencies, archive to .gfvbot/env.json
gfvbot env-init     # tick-list install of whatever is missing
```

`env` probes build tools, JDK, Maven, the flink/nexmark stack, locally available AI agent CLIs, and machine facts. `env-init` opens the OS-specific tick-list installer: build dependencies, flink / nexmark (both optional — untick to skip), and source-deps (Velox's source-built C++ libraries linked from `/usr/local`; the entry appears once the velox checkout exists).

Done when a rerun of `gfvbot env` reports no gaps.

### Step 5: build the GFV stack and start the cluster

```bash
bash <installed-skill>/bin/compile.sh     # velox4j + gluten-flink jars land in /opt/flink/lib/
/opt/flink/bin/start-cluster.sh
```

`compile.sh` is the build entry installed with the plugin's flink-velox-build skill. With the jars in `/opt/flink/lib/` and the cluster up, the environment is ready.

### Step 6: start your first AI-assisted task

```bash
gfvbot prompt stateful-operator-development
```

Prints the plugin's task template. Fill in the placeholders, start the AI agent at the project root (`claude` or `opencode`), paste, and send — a TopN task for example:

```text
> Develop the `TopN` stateful operator for gluten-flink.
> - Goal: emit the Top-N bids ranked by price
> - Verification: run Nexmark query `q19` against the cluster and compare the output with native Flink
> - Acceptance: q19 output matches the native baseline; q0-q18 must not regress
> - Notes: none
> Follow the installed stateful-operator-development workflow; start from the SPEC stage.
```

Or let the AI agent fill the template for you (run inside the target project — it reads the plugin docs and the project's source files):

```bash
gfvbot prompt stateful-operator-development --task "develop a TopN operator, verify with nexmark q19" --tool claude --file topn-prompt.md
```

From here on, coding is AI-assisted: the plugin's workflow carries the task from SPEC to verification, its skills build the stack and run the tests, and its docs explain the internals along the way.

## Other commands

| Command | Effect |
|---|---|
| `gfvbot uninstall <plugin> [--tool <agent>]` | remove a plugin (interactive picker when installed under several agents) |
| `gfvbot list` | show what is installed and what the repo offers |
| `gfvbot help` | full command and flag reference |
| `bash plugins/<plugin>/install.sh <agent>` | install a plugin without the CLI, directly from a clone of this repo |
| `bash tests/run-tests.sh --fast` | L1 static checks: manifests, naming, dependency rules, dry-run |
| `bash tests/run-tests.sh --e2e` | installer lifecycle smoke test in a disposable sandbox |
| `bash tests/run-tests.sh --incremental` | full checks only when `plugins/` or `shared/` changed |
