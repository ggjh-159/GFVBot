# GFVBot

[English](README.md) | [中文](README.zh.md)

GFVBot is the AI foundation for GFV (the gluten-flink-velox integration track). Everything is organized as plugins: one plugin per development scenario, self-contained with that scenario's full development workflow, agent definitions, skills, and reference docs. Once installed into a target project, a plugin runs in that project's AI agent environment.

> Status: the framework (installer, adapters, tests) is complete; plugin content (skills / agents / docs) is still being filled in.

## Repository layout

| Directory | Responsibility |
|---|---|
| `plugins/` | Scenario plugins, one directory per scenario |
| `shared/` | Knowledge assets shared across plugins (skills / docs / templates) |
| `installer/` | Installer engine and AI agent adapters (claude / opencode / codex / dsh) |
| `tests/` | Tests and guardrails for the content assets |

## Plugins

| Plugin | Scenario |
|---|---|
| `stateless-expression-development` | Stateless expression development: end-to-end function integration across velox / velox4j / gluten-flink |
| `stateful-operator-development` | Operator development: planning, execution, state, and data structures of stateful operators |
| `aggregate-function-development` | Aggregate function development: velox Aggregate implementations, the accumulate/merge/finalize chain, and batch integration |
| `performance-optimization` | Performance: benchmark comparison, profiling, bottleneck analysis, and the optimization loop |

## Installation

Option 1 (CLI, recommended):

```bash
bash installer/setup.sh
cd /path/to/gfv
gfvbot install stateful-operator-development                # pick the AI agent interactively
gfvbot install stateful-operator-development --tool claude  # or specify it directly
```

For all other commands and flags, run `gfvbot help`.

Option 2 (directly from a clone of this repo):

```bash
cd /path/to/gfv
bash /path/to/gfvbot/plugins/stateful-operator-development/install.sh claude   # installs into the current directory
```

Two AI agents are currently selectable: `claude` (Claude Code) and `opencode`. The `codex` and `dsh` (DeepSeek Harness) adapters are ready and will be enabled once verification environments are available.

## Initialization walkthrough

Bringing a bare machine to a ready-to-build GFV workspace is the same command sequence on every supported OS — `env-init` dispatches to the OS-specific backend internally (openEuler, CentOS 9, Ubuntu/Debian; on CentOS 7 the source-deps entry is absent because its archived vault repos cannot drive the velox setup script):

```bash
bash installer/setup.sh      # 1. install the gfvbot CLI
cd /path/to/gfv              #    the target project root; run everything below from here
gfvbot install <plugin>      # 2. install a scenario plugin (interactive AI-agent picker)
gfvbot clone                 # 3. velox / velox4j / gluten / flink under repos/ (installs git when missing)
gfvbot env                   # 4. scan dependencies into .gfvbot/env.json
gfvbot env-init              # 5. tick-list install: build deps, flink / nexmark, source-deps
```

`clone` leads the setup and installs git itself when the package manager can provide it, so the repos land before any installer pass. By the time the installer runs, the velox checkout exists and the tick-list carries source-deps — one pass with everything ticked completes any machine, bare or not (`gfvbot env` offers exactly that pass when the scan finds gaps; `gfvbot env-init` opens it directly).

Every step resumes on a machine that is already partway there: detected dependencies are skipped, existing repos are left untouched, and existing configuration is only filled in when absent, never overwritten.

With the workspace in place, the flink-velox-build skill builds the stack and the cluster starts directly (the stock tarball's all-comment flink-conf.yaml was filled in at flink install time, and the build pins the cluster JDK):

```bash
bash <installed-skill>/bin/compile.sh     # velox4j + gluten-flink jars land in /opt/flink/lib/
/opt/flink/bin/start-cluster.sh
```

## Using an installed plugin

`gfvbot prompt` prints a plugin's task template; pass `--task` with `--tool` to have the AI agent generate the complete prompt (run it inside the target project — the agent reads the plugin docs and the project's source files to fill it in), and `--file` to write the result to a file:

```bash
gfvbot prompt stateful-operator-development
gfvbot prompt stateful-operator-development --task "develop a TopN operator, verify with nexmark q19" --tool claude --file topn-prompt.md
```

Claude Code:

```bash
cd /path/to/gfv
claude
```
```text
> <paste the filled-in task template>
```

opencode:

```bash
cd /path/to/gfv
opencode
```
```text
> <paste the filled-in task template>
```

Use `gfvbot list` to see what is installed and what the repo offers.

## Environment check

`gfvbot env` scans build dependencies (git, cmake, gcc/g++, OpenJDK 8/17, Maven, JAVA_HOME, build tools like ninja/autoconf, and Velox's system-level C++ libraries), the locally available AI agent CLIs, and the flink/nexmark stack, then archives everything to the target project's `.gfvbot/env.json`. The `repos` section records each source repo's path, clone-source URL, upstream URL, and main branch: a fresh scan leaves placeholders with a hint, `gfvbot clone` back-fills them, and hand-editing works too. When dependencies are missing it hands over to the OS-specific installer (`installer/env-init/`; openEuler, CentOS 7/9, and Ubuntu/Debian are covered). The installer's tick-list also covers the runtime stack: flink lands as the official tarball under `/opt/flink-<version>` with a stable `/opt/flink` symlink, and nexmark is cloned from source, built with maven, and its jar deployed into flink's `lib/` — both entries are optional:

```bash
gfvbot env
```

To jump straight to the OS-specific installer yourself (interactive tick-list, install, then a re-scan that refreshes the archive):

```bash
gfvbot env-init
```

## Source repos

`gfvbot clone` lays down the GFV source repos under `<target>/repos/` so every machine gets the same workspace layout. Defaults to the GFV baseline upstreams (velox/velox4j: bigo-sg at `gluten-20260829`, gluten: apache at `main`, flink: apache at `release-1.19`); `--fork <user>` clones your personal forks (github.com/<user>/<repo>) at the same branches, with flink always from the official repo:

```bash
gfvbot clone                     # all four: velox, velox4j, gluten, flink
gfvbot clone velox velox4j       # a subset
gfvbot clone --fork <user>       # velox/velox4j/gluten from your forks, baseline branches
gfvbot clone --shallow           # --depth 1: smaller download, no full history
```

Existing repos are skipped; after cloning, version control is plain git. A failed clone removes its partial directory and retries (5 attempts by default); failed repos are summed up at the end, and re-running the same command resumes them — completed repos are skipped. Cloned (or skipped) repos have their path, clone-source URL (your fork under `--fork`), upstream URL, and main branch back-filled into the `repos` section of `.gfvbot/env.json`.

## Source-built C++ libraries

Beyond the package-manager dependencies, the GFV build links Velox's source-built C++ libraries (boost, the folly chain, protobuf, arrow, ...) from `/usr/local`. They are installed through the env-init tick-list: run `gfvbot env-init` after `gfvbot clone` and tick `source-deps` — the entry only appears once the velox checkout exists, and `gfvbot clone` prints a reminder at the end. The installs are driven by the official setup script shipped in the velox checkout, so every version stays pinned by the workspace; the library list itself is parsed from that script, so it always matches the checkout.

Libraries already detectable under `/usr/local` are skipped, so reruns only build what is missing; the build stops at the first failure since later libraries build against earlier ones.

## Uninstall

```bash
gfvbot uninstall stateful-operator-development            # interactive tick-list when installed under several agents
gfvbot uninstall stateful-operator-development --tool claude
```

## Testing

```bash
bash tests/run-tests.sh --fast         # L1 static checks: manifests, naming, dependency rules, dry-run
bash tests/run-tests.sh --e2e          # installer lifecycle smoke test in a disposable sandbox
bash tests/run-tests.sh --incremental  # full checks only when plugins/ or shared/ changed
```
