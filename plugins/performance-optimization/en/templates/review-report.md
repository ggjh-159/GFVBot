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
| Reference | `<SPEC/DESIGN/IMPLEMENTATION/VERIFY path; e2e/perf/REPORT.md>` |

## Conclusion

**Review verdict: pass / fail**

(Any required-level issue means fail.)

---

## A. SPEC review (filled for the SPEC review)

| Audit item | Finding | Basis |
|---|---|---|
| Specification complete (all template sections present) | | |
| Baseline numbers come from the actual `e2e/perf/REPORT.md` artifact (an estimate or paraphrase is a fail) | | |
| Target ratio or gain decidable and verifiable | | |
| Acceptance includes "the query set must not regress in correctness"; constraints state the fixed benchmark and GFV reuse=false only | | |
| Verification plan covers the acceptance criteria | | |

## B. Design review (filled for the design review)

| Audit item | Finding | Basis |
|---|---|---|
| Within SPEC scope; out-of-scope items written back to the SPEC | | |
| Layered-localization evidence chain complete: every layer conclusion backed by ratio / web UI / source evidence (DESIGN §2) | | |
| Attribution grounded (a one-sentence attribution with an evidence chain, DESIGN §3) | | |
| Plan comparison table complete: gain x risk x change scope, the selected plan with a recommended basis (DESIGN §3) | | |
| Semantics-unchanged guarantee and correctness regression strategy explicit (DESIGN §3, §5.2) | | |
| Cites concrete paths/class names/commands, typography and evidence discipline met; the tool-level profiling gap marked "to be consolidated" | | |
| Re-measurement matrix matches the baseline (DESIGN §5.1) | | |

## C. Code review (filled for the code review)

### C1. Scope compliance (mandatory)

| Audit item | Finding | Basis |
|---|---|---|
| flink-velox-format skill check passed (one row per touched repo, log path cited; any violation is a fail) | | |
| The diff stays within the SPEC and design impact list (out of scope = required-level; drive-by refactoring is out of scope) | | |

### C2. Semantics unchanged and benchmark discipline (mandatory)

| Audit item | Finding | Basis |
|---|---|---|
| The optimization does not change query semantics; changes touching the result path have matching regression cases | | |
| Benchmark confs not hand-edited; new runtime configuration goes through the regular path and is recorded | | |

### C3. Unit-test coverage (mandatory; missing = required-level)

| Audit item | Finding | Basis |
|---|---|---|
| Every new/modified production file has tests, normal path + boundary conditions | | |
| Matches the design's §5.2 | | |

### C4. Documentation sync (mandatory)

| Audit item | Finding | Basis |
|---|---|---|
| Changes/deviations/test results stated in IMPLEMENTATION.md match the code item by item (a snapshot frozen before rework = required-level) | | |

## D. Final acceptance (filled for the final acceptance)

| Audit item | Finding | Basis |
|---|---|---|
| Each SPEC acceptance criterion met per VERIFY.md (target ratios reached, correctness not regressed) | | |
| Re-measured ratios, matrix, and `e2e/perf/REPORT.md` agree; all jobs FINISHED | | |
| Coverage claim matches what actually ran | | |
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

Severity: required-level = logic error / semantic drift / benchmark altered / attribution without evidence / coverage gap / doc-vs-implementation contradiction, fail outright; advisory-level = improvement, non-blocking. Attribution = rework target: design back to the analyst (SPEC/DESIGN), implementation back to the developer, tests back to the verifier's artifacts, docs back to the owning agent.
