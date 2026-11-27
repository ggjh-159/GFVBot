---
name: flink-velox-format
description: Run the canonical format entry of velox/velox4j/gluten over the changed files in check or fix mode, exiting non-zero on violations — the single format verdict shared by every plugin's pre-commit rule and the code-review step 0.
---

# Flink-velox code format check

Format problems are a machine verdict: they never deserve human review attention and never belong in a commit. This skill is the single entry shared by every plugin — no commit before a passing check, and code review's step 0 takes the same verdict.

## Dispatch per repo

| Repo | check | fix | Coverage |
|---|---|---|---|
| velox | each changed C/C++ file through `clang-format --dry-run --Werror` (per the repo-root `.clang-format`) | `git add -A` then `make format-fix CHECK_BASE=<base>` — check.py refuses unstaged changes; the default base is `gluten-20260829`, overridable via `VELOX_CHECK_BASE` | plan nodes, operator/function implementations, tests |
| velox4j | `mvn -q spotless:check` | `mvn -q spotless:apply` | the whole module |
| gluten | changed C/C++ files through clang-format; Java at the `gluten-flink/` root via `mvn -q spotless:check -pl planner,ut` | `clang-format -i`; `spotless:apply -pl planner,ut` | `cpp/` plus gluten-flink's planner and ut |

The repo kind is detected from the layout (`gluten-flink/` → gluten, `velox/` plus `.clang-format` → velox, `pom.xml` in a dir named velox4j → velox4j); pass `--kind` when detection fails. Changed files = uncommitted work (staged, unstaged, untracked new files); `--base <git-ref>` adds everything changed since that ref.

## Procedure

1. Before committing: `bash bin/format.sh check <repo-path> [--base <git-ref>]`, output redirected to `tmp/<task-name>/logs/cmd-outputs/format-<repo>-<time>.log`.
2. On violations: `bash bin/format.sh fix <repo-path> [--base ...]`, then re-run check. fix touches format only — recompile and re-run unit tests afterwards, and never mix a format fix with semantic changes in the same commit.
3. Review step 0: the reviewer runs check on every touched repo and rules by the exit code; IMPLEMENTATION.md and the review report cite the log path as the "format check passed" evidence.

## Reading the result

- Exit codes: 0 clean, 1 violations (check) or tool failure (fix), 2 usage or environment error.
- The spotless checks cover whole modules, so the violation list may include files outside this change set — that is pre-existing repo debt: note it, do not fix it, and never let it widen the change set.
- Commands follow each repo's actual toolchain (velox's `check.py`/Makefile targets, the spotless plugin version): on first use in a repo confirm the command works; when it does not, report an environment gap — never skip silently and never substitute an ad-hoc command.
- Any "format passed" claim needs a check log path; without a log it counts as not checked.
