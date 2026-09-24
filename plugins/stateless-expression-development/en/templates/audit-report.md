# Audit Report — <task-name>

> The ruling is either **pass** or **fail** — there is no "pass with conditions". A fail must carry concrete audit findings (see the issue list). Copy this template three times for the design audit (DESIGN_AUDIT), code audit (CODE_AUDIT), and result audit (RESULT_AUDIT), deleting the irrelevant sections in each.

## Audit Info

| Item | Content |
|---|---|
| Audit type | <design/code/result> |
| Audited artifact | `<path of the file under audit>` |
| Round | <1 for the first round, incrementing on re-audit; the report refreshes in place to the latest round> |
| Date | <YYYY-MM-DD> |
| Reference | `<SPEC/DESIGN/IMPLEMENTATION/TEST_REPORT path>` |

## Ruling

**Audit ruling: pass / fail**

(pick one, delete the other. Any HIGH issue means fail.)

---

## A. Design Audit (fill for the design audit)

### A1. Soundness

| Audit item | Verdict | Basis |
|---|---|---|
| Overall approach sound and path feasible | <holds/does not hold> | |
| Reuse decisions correct (no direct reuse where semantics differ) | | |
| Registered under the flinksql namespace, not reusing spark/presto | | |
| All three layers (velox / mapping / gluten) present, no gaps | | |

### A2. Support Verification

<verify every supporting claim of the design: does the source evidence actually exist, was the semantic comparison checked per dimension, do the signatures cover the SPEC type matrix — an unsupported claim is HIGH>

### A3. Coverage Completeness

| Audit item | Verdict | Basis |
|---|---|---|
| Unit-test matrix includes NULL / boundary / special scenarios | | |
| e2e matrix includes combination / aggregation contexts | | |
| Special-scenario list complete (against the doc card) | | |

## B. Code Audit (fill for the code audit)

### B1. Conformance to Design

| Audit item | Verdict | Basis |
|---|---|---|
| All changes inside the design impact list | | |
| Registration / signatures / naming match §4 | | |
| Mapping entry matches §5 | | |

### B2. Engineering Quality

| Audit item | Verdict | Basis |
|---|---|---|
| Safety (null dereference / out-of-bounds / type truncation ...) | | |
| Unit tests complete (against the §7 matrix) | | |
| Code format passes | | |
| No simpler or faster implementation ignored | | |
| No redundant / unscalable / unreadable code | | |

### B3. Documentation Synced with Implementation

<check item by item: the change list, deviation records, and test results stated in IMPLEMENTATION.md match the landed code — documentation stuck at an early snapshot after multiple rework rounds is this section's most common failure mode and rates HIGH>

| Audit item | Verdict | Basis |
|---|---|---|
| Stated changes match the actual code | <consistent/inconsistent (doc vs actual)> | |
| Deviation records and test results match reality | | |

## C. Result Audit (fill for the result audit)

### C1. Test Results

| Audit item | Verdict | Basis |
|---|---|---|
| Unit tests all pass | | <count and log location> |
| Unit-test scope matches the design §7 matrix | | |
| Lightweight e2e passed (implement-stage self-check) | | |
| Full e2e dual-run consistent (TEST_REPORT) | | |
| e2e scope matches the design §8 matrix | | |
| No regression (existing cases) | | |

## Prior-Round Disposition (fill on re-audit; delete this section on the first round)

A re-audit checks the prior round first, then re-audits in full: mark each prior-round issue's disposition; any carried-over item needs a reason.

| Prior ID | Disposition | Notes |
|---|---|---|
| A-1 | <resolved/carried over> | <carry-over reason / evidence checked> |

## Issue List

| ID | Severity | Attribution | Location | Description | Audit finding (required on fail) |
|---|---|---|---|---|---|
| A-1 | <HIGH/MED/LOW> | <design/implementation/test/docs> | | | |

Severity: HIGH = logic error / iron-rule violation / coverage gap / doc-code contradiction — fail immediately; MED/LOW = improvement suggestions, non-blocking. Attribution = rework target: design returns to the architect (SPEC/DESIGN), implementation to the developer, test to the test-artifact owner, docs to the corresponding doc owner; the orchestrator routes by attribution.
