# Review report——<task-name>

> The conclusion is only **pass** or **fail**, nothing else. Copy this template for the SPEC review (SPEC_REVIEW), design review (DESIGN_REVIEW), code review (CODE_REVIEW), and final acceptance (REVIEW_GATE), deleting the irrelevant sections each time.
> A fail must give directly executable revision opinions, each tagged with its attribution (design/implementation/test/docs) — the orchestrator routes rework by attribution. Constructive findings attached to a pass go into the issue list at advisory level and never block.

## Review info

| Item | Content |
|---|---|
| Review type | <SPEC review / design review / code review / final acceptance> |
| Object under review | `<path of the reviewed file>` |
| Round | <1 for the first round, incrementing on re-review; the report refreshes in place to the latest round> |
| Date | <YYYY-MM-DD> |
| Reference | `<SPEC/DESIGN/IMPLEMENTATION/VERIFY path>` |

## Conclusion

**Review verdict: pass / fail**

(Any required-level issue means fail.)

---

## A. SPEC review (filled for the SPEC review)

| Audit item | Finding | Basis |
|---|---|---|
| Specification complete (all template sections present) | | |
| Feasibility conclusion evidenced (existing implementation / type matrix / registration path verified item by item; unverifiable spots marked "to be verified") | | |
| Acceptance criteria verifiable | | |
| Verification plan covers the acceptance criteria | | |

## B. Design review (filled for the design review)

| Audit item | Finding | Basis |
|---|---|---|
| Within SPEC scope; out-of-scope items written back to the SPEC | | |
| Current-state survey honestly graded + reuse dispositions complete (DESIGN §2) | | |
| Type matrix and the four-stage chain (accumulate/partial/merge/finalize) fully covered; NULL and empty-set semantics explicit (DESIGN §3) | | |
| Registration path compliant: flinksql namespace, existing implementations untouched (DESIGN §3) | | |
| Cites concrete paths/class names/commands; typography and evidence discipline met | | |
| Test strategy holds (unit matrix covers type matrix / NULL / partial round trips; e2e has a baseline and the nexmark regression set) | | |

## C. Code review (filled for the code review)

### C1. Scope compliance (mandatory)

| Audit item | Finding | Basis |
|---|---|---|
| flink-velox-format skill check passed (one row per touched repo, log path cited; any violation is a fail) | | |
| The diff stays within the SPEC and design impact list (out of scope = required-level) | | |

### C2. Contract compliance

| Audit item | Finding | Basis |
|---|---|---|
| No existing aggregate implementation rewritten | | |
| Registration only in the flinksql namespace | | |
| Chain complete, test SetUp registration order correct, NULL/empty-set semantics consistent with Flink | | |

### C3. Unit-test coverage (mandatory; missing = required-level)

| Audit item | Finding | Basis |
|---|---|---|
| Every new/modified production file has tests, with cases for the type matrix / NULL / partial round trips | | |
| Matches the design's §5.1 matrix | | |

### C4. Documentation sync (mandatory)

| Audit item | Finding | Basis |
|---|---|---|
| Changes/deviations/test results stated in IMPLEMENTATION.md match the code item by item (a snapshot frozen before rework = required-level) | | |

## D. Final acceptance (filled for the final acceptance)

| Audit item | Finding | Basis |
|---|---|---|
| Each SPEC acceptance criterion met per VERIFY.md | | |
| Coverage claim matches what actually ran | | |
| No regression | | |
| Residual risk listed and acceptable | | |

## Prior-round issue disposition (filled on re-review; delete this section in the first round)

A re-audit first checks the prior-round dispositions, then re-audits in full:

| Prior number | Disposition | Notes |
|---|---|---|
| <number> | <resolved / carried over> | <carry-over reason / evidence checked> |

## Issue list

| # | Severity | Attribution | Location | Description | Revision opinion (required on fail, directly executable) |
|---|---|---|---|---|---|
| 1 | <required-level / advisory-level> | <design/implementation/test/docs> | | | |

Severity: required-level = logic error / scenario iron-rule violation / coverage gap / doc-vs-implementation contradiction, fail outright; advisory-level = improvement, non-blocking. Attribution = rework target: design back to the architect (SPEC/DESIGN), implementation back to the developer, tests back to the verifier's artifacts, docs back to the owning agent.
