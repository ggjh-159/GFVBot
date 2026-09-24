---
name: flink-velox-code-review
description: Structured review of GFV code changes — layer boundaries, resource management, exception handling, serialization compatibility, memory safety, and common anti-patterns, driven by a change-surface analysis and a fixed checklist.
---

# flink-velox-code-review

## Core principles

1. Diff first — review only what changed; the unchanged baseline is out of scope by default.
2. Change-driven — the change-surface tags decide which checklist dimensions apply; no shotgunning.
3. Checklist-driven — walk the fixed checklist; free-form exploration is secondary.
4. Format first — machine-checkable format issues are eliminated first, consuming no human-review attention.
5. Output constraint — one line per issue, with `file:line`; never emit code blocks or fix suggestions in the review output.

## Procedure

### Stage 0 — format baseline

Changed files pass a machine format check first; format failures block the deep review:

- C++ changes (velox repo, the gluten repo's `cpp/`): run `clang-format --dry-run --Werror <changed files>` per the repo-root `.clang-format`; the gluten repo's CI-equivalent entry is `dev/check.py format`.
- Java changes (velox4j, gluten-flink): check basic format consistency — import order, trailing whitespace, tab mixing; when the repo carries a format toolchain (spotless and the like), run the repo's entry.
- Format issues go into the issue list (severity HIGH); fixing format does not change the change-surface tags.

### Stage 1 — change-surface analysis

Input: the diff (`git diff` output preferred), or a changed-file list with line ranges. Run `scripts/diff-parser.sh` (or apply its tag rules by hand) to get the file list, languages, and change tags. The tags: `arrow-res`, `exception`, `json-serde`, `rexcall`, `operator`, `pointer`, `numeric`, `import`, `api-change`, `other`.

### Stage 2 — scripted checks

Run the static scripts where the tags call for them:

- `scripts/layer-dep-check.sh <workspace-root>` — layer boundary violations (planner importing runtime internals, runtime importing planner classes, velox4j public API leaking internals). Discovers module paths under `<workspace-root>/repos/`.
- `scripts/anti-pattern-grep.sh <workspace-root> [changed-files]` — grep-level anti-patterns: empty catch blocks, Arrow vectors outside try-with-resources, allocations inside processElement, magic numbers, uninitialized C++ variables.

Script findings are leads, not verdicts: confirm each against the diff before reporting.

### Stage 3 — checklist walk

Walk checklist.md section by section, in order, executing only the sections the tags trigger. Each item yields `- [ ]` (no issue found) or `- [x]` (issue, with `file:line`).

## Input contract

Required: the code change as a diff, or a changed-file list with ranges; full-file mode only when explicitly requested. Optional: the SPEC/design impact list and the task's allowed-modification scope — when present, the scope-compliance check is mandatory and an out-of-scope change is a critical fail.

## Output contract

One line per issue: `severity — file:line — problem`. Severities: CRITICAL (review verdict becomes fail), HIGH, MEDIUM, LOW. End with the verdict (`pass` / `pass with suggestions` / `fail`) and the counts per severity. No code blocks, no patch sketches, no restating of unchanged code.
