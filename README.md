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

Bringing a bare machine to a ready-to-build GFV workspace (openEuler, CentOS 7/9, and Ubuntu/Debian are supported):

```bash
bash installer/setup.sh      # 1. install the gfvbot CLI
cd /path/to/gfv              #    the target project root; run everything below from here
gfvbot install <plugin>      # 2. install a scenario plugin (interactive AI-agent picker)
gfvbot clone                 # 3. velox / velox4j / gluten / flink under repos/ (installs git when missing)
gfvbot env                   # 4. scan dependencies into .gfvbot/env.json
gfvbot env-init              # 5. tick-list install: build deps, flink / nexmark, source-deps
```

Every step resumes: detected dependencies are skipped, existing repos and configuration are left untouched — rerun the same command after an interruption to continue.

With the workspace in place, the flink-velox-build skill builds the stack and the cluster starts directly:

```bash
bash <installed-skill>/bin/compile.sh     # velox4j + gluten-flink jars land in /opt/flink/lib/
/opt/flink/bin/start-cluster.sh
```

## Using an installed plugin

`gfvbot prompt` prints the plugin's task template:

```bash
gfvbot prompt stateful-operator-development
```

Fill in the placeholders, start the AI agent at the target project root, paste, and send. Using a TopN task as the example:

```bash
cd /path/to/gfv
claude          # or opencode
```
```text
> Develop the `TopN` stateful operator for gluten-flink.
> - Goal: emit the Top-N bids ranked by price
> - Verification: run Nexmark query `q19` against the cluster and compare the output with native Flink
> - Acceptance: q19 output matches the native baseline; q0-q18 must not regress
> - Notes: none
> Follow the installed stateful-operator-development workflow; start from the SPEC stage.
```

Or let the AI agent fill it in: pass `--task` with `--tool` (run inside the target project — the agent reads the plugin docs and the project's source files), and `--file` to write the result to a file:

```bash
gfvbot prompt stateful-operator-development --task "develop a TopN operator, verify with nexmark q19" --tool claude --file topn-prompt.md
```

Use `gfvbot list` to see what is installed and what the repo offers.

## Environment check

`gfvbot env` scans the following and archives the results to the target project's `.gfvbot/env.json`:

- Build dependencies: git, cmake, gcc/g++, OpenJDK 8/17, Maven, JAVA_HOME
- The build-tools group and Velox's system-level C++ library group (probed and installed as groups)
- Locally available AI agent CLIs
- The flink/nexmark stack
- Machine facts: OS, kernel, arch, CPU, memory, disk

The `repos` section records each source repo's path, clone-source URL, upstream URL, and main branch:

- a fresh scan leaves placeholders with a hint
- `gfvbot clone` back-fills them after cloning
- hand-editing works too

```bash
gfvbot env
```

When the scan finds gaps, `env` hands over to the OS-specific installer. To open that installer directly (interactive tick-list, install, then a re-scan that refreshes the archive):

```bash
gfvbot env-init
```

The env-init tick-list also covers the runtime stack: flink and nexmark are both optional entries — leave them unticked to skip.

## Source repos

`gfvbot clone` lays down the GFV source repos under `<target>/repos/` so every machine gets the same workspace layout. By default it clones the baseline branches from the baseline upstreams:

| Repo | Upstream | Branch |
|---|---|---|
| velox | bigo-sg | `gluten-20260829` |
| velox4j | bigo-sg | `gluten-20260829` |
| gluten | apache | `main` |
| flink | apache | `release-1.19` |

```bash
gfvbot clone                     # all four repos
gfvbot clone velox velox4j       # a subset
gfvbot clone --fork <user>       # velox/velox4j/gluten from your forks (github.com/<user>/<repo>), same branches; flink always official
gfvbot clone --shallow           # --depth 1 shallow clone
```

See `gfvbot help` for the full flag reference. Existing repos are skipped and re-running the same command resumes what is left; after cloning, version control is plain git.

## Source-built C++ libraries

Beyond the package-manager dependencies, the GFV build links Velox's source-built C++ libraries (boost, the folly chain, protobuf, arrow, ...) from `/usr/local`. They are installed through the env-init tick-list: run `gfvbot env-init` after `gfvbot clone` and tick `source-deps` — the entry only appears once the velox checkout exists, and `gfvbot clone` prints a reminder at the end.

Libraries already detectable under `/usr/local` are skipped, so reruns only build what is missing.

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
