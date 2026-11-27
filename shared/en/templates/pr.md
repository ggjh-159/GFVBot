# PR — <task-name>

> PR preparation record for the target project. Prepared after acceptance; upstream community drafts live separately under `upstream/` and are submitted only after final user confirmation.
> Checklist items that do not apply are written as "not applicable + a one-line reason", never deleted.

## 1. Documentation updates

Target-project documentation tree entries to sync:

| Doc | Update | Status |
|---|---|---|
| `docs/<path>` | Final design document archived | <updated/pending> |

## 2. Commit plan

Each touched repo gets its own commit breakdown, one topic per commit; drop rows for repos not touched:

| Repo | # | Commit message | Files |
|---|---|---|---|
| velox | 1 | | |
| velox4j | 1 | | |
| gluten | 1 | | |

## 3. PR description

The description must answer "why": what the problem is and why this approach — a description that only lists "what was done" does not qualify and is sent back for rewrite.

- Title: <one line>
- Background and problem (why the change is needed): <the symptom or gap, its impact, what happens without the change; cite SPEC "Goal and scope" and the feasibility assessment>
- Approach and rationale (why this approach): <the design-choice basis, alternatives considered and why they were rejected, the key trade-offs; cite the DESIGN plan section and the ruled pending decisions>
- Change summary (what was done): <cite IMPLEMENTATION.md §1>
- Verification results: <cite the matching section of the verification report (VERIFY.md or TEST_REPORT.md) and the `e2e/verify/RESULTS.md` path>
- Risks and leftovers: <cite the corresponding SUMMARY.md entries>

## 4. Pre-merge checklist

- [ ] Final review (REVIEW_GATE.md or RESULT_AUDIT.md) signed as passed
- [ ] User gate 3 confirmed
- [ ] IMPLEMENTATION.md consistent with the final code (refreshed in place after rework)
- [ ] All unit tests pass
- [ ] Verification results cited with path and conclusion (e2e verification and performance comparison as applicable to the task)
- [ ] Documentation updates landed or listed as pending
- [ ] Upstream drafts under `upstream/` ready for user confirmation when upstream repos are touched
- [ ] No issue or PR submitted automatically
