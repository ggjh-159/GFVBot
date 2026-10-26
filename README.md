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

## Four steps from a bare machine to AI-assisted coding

Supported OSes: openEuler, CentOS 7/9, Ubuntu/Debian. Run the steps in order — each one builds on the previous, and together they take you from an empty machine to a working GFV workspace where the AI agent does the coding with you. Every step resumes: detected dependencies are skipped, existing repos and configuration are left untouched, so after an interruption just rerun the same command.

### Step 1: install the gfvbot CLI

```bash
bash installer/setup.sh
```

Installs the `gfvbot` command-line tool. Done when `gfvbot help` prints the command list.

### Step 2: clone the GFV source repos

```bash
cd /path/to/gfv      # the target project root; run all further commands from here
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

### Step 3: scan the environment and fill the gaps

```bash
gfvbot env          # scan dependencies, archive to .gfvbot/env.json
gfvbot env-init     # tick-list install of whatever is missing
```

`env` probes build tools, JDK, Maven, the flink/nexmark stack, locally available AI agent CLIs, and machine facts. `env-init` opens the OS-specific tick-list installer: build dependencies, flink / nexmark (both optional — untick to skip), and source-deps (Velox's source-built C++ libraries linked from `/usr/local`).

Done when a rerun of `gfvbot env` reports no gaps.

### Step 4: install a scenario plugin

```bash
gfvbot install stateful-operator-development
```

Installs the plugin into the current project — its skills, its docs, and its development workflow. Without `--tool` it asks for the AI agent interactively; add `--tool claude` to skip the question. Selectable today: `claude` (Claude Code) and `opencode`; the `codex` and `dsh` (DeepSeek Harness) adapters are ready and open once verification environments are available.

Content language follows the output language (`gfvbot lang`); override with `--lang en|zh`. Exactly one language lands — no en/zh layer inside the project — and switching language is a reinstall over the top.

Done when `gfvbot list` shows the plugin as installed.

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
