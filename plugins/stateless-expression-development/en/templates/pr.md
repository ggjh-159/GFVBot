# PR — <task-name>

> PR preparation record for the target project. Prepared after the code audit passes and user gate 2 is confirmed; upstream community drafts live separately under `upstream/` (retro stage) and are submitted only after final user confirmation.
> Checklist items that do not apply are written as "not applicable + a one-line reason", never deleted.

## 1. Commit plan

Each touched repo gets its own commit breakdown, one topic per commit:

| Repo | # | Commit message | Files |
|---|---|---|---|
| velox | 1 | | |
| velox4j | 1 | | |
| gluten | 1 | | |

## 2. PR description

- Title: <one line>
- Background and motivation: <cite DESIGN.md §1>
- Change summary: <cite IMPLEMENTATION.md §1>
- Verification results: <cite TEST_REPORT.md §6 and the `e2e/verify/RESULTS.md` path>

## 3. Pre-merge checklist

- [ ] CODE_AUDIT.md verdict passed
- [ ] User gate 2 confirmed
- [ ] IMPLEMENTATION.md consistent with the final code (refreshed in place after rework)
- [ ] All unit tests pass
- [ ] Lightweight e2e self-test passed (job reached FINISHED)
- [ ] No issue or PR submitted automatically
