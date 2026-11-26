# PR — <task-name>

> PR preparation record for the target project. Prepared after acceptance; upstream community drafts live separately under `upstream/` and are submitted only after final user confirmation.
> Checklist items that do not apply are written as "not applicable + a one-line reason", never deleted.

## 1. Documentation updates

Target-project documentation tree entries to sync:

| Doc | Update | Status |
|---|---|---|
| `docs/<path>` | Final design document archived | <updated/pending> |

## 2. Commit plan

Commit breakdown for the target-project repo, one topic per commit:

| # | Commit message | Files |
|---|---|---|
| 1 | | |

## 3. PR description

- Title: <one line>
- Background and motivation: <cite SPEC "Goal and scope">
- Change summary: <cite IMPLEMENTATION.md §1>
- Verification results: <cite VERIFY.md §7 and the `e2e/verify/RESULTS.md` path>
- Risks and leftovers: <cite the corresponding SUMMARY.md entries>

## 4. Pre-merge checklist

- [ ] REVIEW_GATE.md signed `pass`
- [ ] User gate 3 confirmed
- [ ] IMPLEMENTATION.md consistent with the final code (refreshed in place after rework)
- [ ] All unit tests pass
- [ ] e2e verification results cited with path and conclusion
- [ ] Documentation updates landed or listed as pending
- [ ] Upstream drafts under `upstream/` ready for user confirmation when upstream repos are touched
- [ ] No issue or PR submitted automatically
