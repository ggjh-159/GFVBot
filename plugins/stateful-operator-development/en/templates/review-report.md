# Review report — <task-name>

> The verdict is only **pass** or **fail**, nothing in between. Copy this template for the SPEC review (SPEC_REVIEW), design review (DESIGN_REVIEW), code review (CODE_REVIEW), and final acceptance (REVIEW_GATE), deleting the irrelevant sections each time.
> A fail must carry directly executable revision opinions, each tagged with its attribution (design/implementation/test/docs) — the orchestrator routes rework by attribution. Constructive findings attached to a pass go into the issue list at advisory level, non-blocking.

## Review info

| Item | Content |
|---|---|
| Review type | <SPEC review/design review/code review/final acceptance> |
| Review target | `<path of the file under review>` |
| Round | <1 on first review, incrementing on re-audit; the report refreshes in place to the latest round> |
| Date | <YYYY-MM-DD> |
| Reference | `<SPEC/DESIGN/IMPLEMENTATION/VERIFY path>` |

## Verdict

**Review verdict: pass / fail**

(Any single required-level issue means fail.)

---

## A. SPEC review (fill in for the SPEC review)

| Audit item | Ruling | Basis |
|---|---|---|
| Specification complete (every template section present) | | |
| Feasibility conclusion evidenced (checked item by item against the implementation-contract doc) | | |
| Acceptance criteria verifiable | | |
| Verification plan covers the acceptance criteria | | |

## B. Design review (fill in for the design review)

| Audit item | Ruling | Basis |
|---|---|---|
| Within SPEC scope; out-of-scope items written back to SPEC | | |
| Contract matching complete (handle selection / five-and-seven-step lifecycle / iron rules, DESIGN §3) | | |
| Impacted layers complete (velox node/operator/tests, velox4j mirror, gluten override) | | |
| Cites concrete paths/class names/commands, no generic description | | |
| Typography discipline met (bullets, one fact per bullet + anchors, no prose) | | |
| Basis discipline met (a one-line basis per conclusion; "already exists / zero-change" claims verified) | | |
| Current-state survey honestly graded (half-done/missing items evidenced with file:line, DESIGN §2) | | |
| Reuse dispositions complete (including "not adopted + reason", DESIGN §2) | | |
| Alignment list covers every behavior point; alignment-grade wording holds up (trimming carries a ruling basis, DESIGN §5) | | |
| Risks checked against the contract pitfall table row by row, matching row count (DESIGN §8) | | |
| Limitations numbered with TODOs; every limitation is an open problem, not final semantics (DESIGN §9) | | |
| Pending decisions well-formed: self-contained background + comparison table + recommendation + a one-line basis (DESIGN §10) | | |
| Test strategy holds (unit matrix includes restore/rescale — mandatory for new state layouts, existing suites may serve as evidence for pure reuse; e2e has a baseline) | | |

## C. Code review (fill in for the code review)

### C1. Scope compliance (mandatory)

| Audit item | Ruling | Basis |
|---|---|---|
| Diff entirely inside the SPEC and design impact lists (out of scope = required level) | | |

### C2. Contract conformance

| Audit item | Ruling | Basis |
|---|---|---|
| transformation stays non-keyed | | |
| typed API (no legacy-plane calls) | | |
| Lifecycle discipline (wiring timing / close order / advance at batch boundaries / fail loud) | | |

### C3. Unit-test coverage (mandatory; missing = required level)

| Audit item | Ruling | Basis |
|---|---|---|
| Every new or modified production file has unit tests, normal path + boundary conditions | | |
| Matches the design §7.1 matrix | | |

### C4. Documentation sync (mandatory)

| Audit item | Ruling | Basis |
|---|---|---|
| IMPLEMENTATION.md's changes/deviations/test results match the code item by item (a snapshot frozen before rework = required level) | | |

## D. Final acceptance (fill in for final acceptance)

| Audit item | Ruling | Basis |
|---|---|---|
| Each SPEC acceptance criterion met per VERIFY.md | | |
| Coverage claims match what actually ran | | |
| No regressions | | |
| Residual risks listed and acceptable | | |

## Prior-round disposition (fill in on re-audit; delete on first review)

A re-audit first checks the prior round's disposition, then re-audits in full:

| Prior ID | Disposition | Notes |
|---|---|---|
| <ID> | <resolved/carried over> | <deferral reason / evidence checked> |

## Issue list

| ID | Severity | Attribution | Location | Description | Revision opinion (required on fail, directly executable) |
|---|---|---|---|---|---|
| 1 | <required/advisory> | <design/implementation/test/docs> | | | |

Severity: required = logic error / contract iron-rule violation / missing coverage / doc-code contradiction, an immediate fail; advisory = improvement, non-blocking. Attribution = rework routing: design returns to the architect (SPEC/DESIGN), implementation to the developer, tests to the verifier's artifacts, docs to the owning agent.
