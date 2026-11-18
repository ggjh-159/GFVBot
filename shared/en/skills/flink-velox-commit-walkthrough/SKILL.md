---
name: flink-velox-commit-walkthrough
description: Commit walkthrough after code review passes — one human-review document per commit, organized by repo: change intent and process impact, key-snippet walkthrough, call-chain context, organized by architectural layering.
---

# flink-velox-commit-walkthrough

## Core principles

1. One commit one file, directories per repo — the reviewer browses by repo, commits and documents map one to one.
2. Self-contained — the walkthrough remains independently reviewable outside the development session: call chains, data flow, and design rationale are embedded in the document, leaving no context gap.
3. Snippet-analysis pairing — every key code snippet carries its analysis; excerpt only the ranges that carry decisions, never whole files.
4. Bulletized expression — analysis is built from bullets, one piece of information per bullet; redundant narration and zero-information restatement are suppressed.
5. Information density — every analysis bullet points at one design decision or behavior change; boilerplate filler ("this function implements its functionality" style) is never written.

## When it runs

After code review (CODE_REVIEW.md) passes and before the user gate 2 presentation, executed by the developer. Rework fixes are amended into the commit that introduced the problem (the id regenerates, no separate fix commits); affected walkthrough files refresh in place (the ids in the H1 and the gate list update accordingly), and the IMPLEMENTATION.md coverage declaration is updated to match. At presentation time the walkthrough files are listed line by line in the gate-2 material list (repo, commit short hash and title, file path) and confirmed commit by commit — each file is first presented with a gist line (short hash, title, one-sentence change intent) so the user can verify the file matches the commit, then the file is reviewed and released one by one.

## Output layout

```text
tasks/<task-name>/commits/
  velox/01-<slug>.md
  velox4j/01-<slug>.md
  gluten/01-<slug>.md
```

Cover only the commits produced by the task — the range is `git log <base>..HEAD`, the base being the task starting point recorded in TASK_STATE; a repo with no changes gets no directory. File names carry a two-digit sequence prefix, incrementing from 01 in commit order (the order of `git log --reverse <base>..HEAD`); the sequence is the review order. File names carry no commit id — the id appears only in the file's H1 and the gate-2 list, so an amend needs no rename; only a rebase that changes the order renumbers the sequence.

## Content specification

**Change intent**: summarize the change intent (implement a capability / fix a defect / structural adjustment), the motivation (which SPEC or design item it corresponds to, what triggered it), and the behavior change achieved. When the commit changes or refines an execution flow, a data path, or a lifecycle sequence, add a separate **process impact** block: the before/after flow difference and the new path's entry points.

**Snippet walkthrough**: every key snippet carries a three-element analysis —

- what changed: what this snippet modifies and how it maps to the new behavior;
- why it matters: why the change is worth making, what problem it solves, on which path it takes effect;
- how it was done: why this approach — the trade-offs made and their basis (checked against the design document or the contract).

**Call-chain context**: place the snippet in the call graph — the upstream caller, the snippet's own responsibility, the downstream callee, and where the data comes from and flows to; the principle is to make the context of every piece of implementation code fully visible, so the reviewer can locate its role in the system without replaying the session.

**Organization**: snippets progress through the architectural layers (top-down along the call direction, e.g. planner rewrite -> cross-language plan node -> native operator lifecycle -> state access); when a commit's snippets have no layer dependency, lay them out flat grouped by cohesion instead of forcing an order.

## File skeleton

```markdown
# <short-hash> <commit title>

## Change intent

<intent, motivation, behavior change; anchors into the SPEC/design>

## Process impact (only when the commit changes or refines a flow)

<before/after difference of the execution flow / data path / sequencing, and the new path's entry points>

## Snippet walkthrough

### <layer name or theme> (layered progression; flat by cohesion when no layering)

```<lang>
<code snippet — only the decision-carrying key ranges>
```

- what changed: <what>
- why it matters: <why>
- how it was done: <approach and trade-offs>
- call chain: <upstream -> this snippet -> downstream; data flow>
```

## Input contract

Required: the task branch commit list (`git log --oneline <base>..HEAD`) and each commit's diff. Recommended: DESIGN.md (basis for the layering and the how-it-was-done analysis), IMPLEMENTATION.md (change-grouping cross-check).

## Output contract

One markdown file per commit, under `tasks/<task-name>/commits/` organized by repo. Each file covers all key snippets of its commit, each snippet with the three-element analysis and call-chain context; no whole-file pasting, no boilerplate filler. When all walkthroughs are done, append a coverage declaration to IMPLEMENTATION.md (repos x commit count x file count) — that declaration is the data source of the gate-2 material list, and every per-commit file must be locatable in it.
