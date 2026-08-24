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

`gfvbot env` scans build dependencies (git, cmake, gcc/g++, OpenJDK 8/17, Maven, JAVA_HOME, build tools like ninja/autoconf, and Velox's system-level C++ libraries), the locally available AI agent CLIs, and the flink/nexmark stack, then archives everything to the target project's `.gfvbot/env.json`. The `repos` section records each source repo's path, clone-source URL, upstream URL, and main branch: a fresh scan leaves placeholders with a hint, `gfvbot clone` back-fills them, and hand-editing works too. When dependencies are missing it hands over to the OS-specific installer (`installer/env-init/`):

```bash
gfvbot env
```

To jump straight to the OS-specific installer yourself (interactive tick-list, install, then a re-scan that refreshes the archive):

```bash
gfvbot env-init
```

## Source repos

`gfvbot clone` lays down the GFV source repos under `<target>/repos/` so every machine gets the same workspace layout. Defaults to the GFV baseline upstreams (velox/velox4j: bigo-sg at `gluten-0530`, gluten: apache at `main`, flink: apache at `release-1.19`); `--fork <user>` clones your personal forks (github.com/<user>/<repo>) at the same branches, with flink always from the official repo:

```bash
gfvbot clone                     # all four: velox, velox4j, gluten, flink
gfvbot clone velox velox4j       # a subset
gfvbot clone --fork <user>       # velox/velox4j/gluten from your forks, baseline branches
gfvbot clone --shallow           # --depth 1: smaller download, no full history
```

Existing repos are skipped; after cloning, version control is plain git. A failed clone removes its partial directory and retries (3 attempts by default); failed repos are summed up at the end, and re-running the same command resumes them — completed repos are skipped. Cloned (or skipped) repos have their path, clone-source URL (your fork under `--fork`), upstream URL, and main branch back-filled into the `repos` section of `.gfvbot/env.json`.

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
