---
scheduler: stateful-operator-orchestrator
stages:
  - name: spec
    owner: stateful-operator-architect
  - name: design
    owner: stateful-operator-architect
  - name: implement
    owner: stateful-operator-developer
  - name: verify
    owner: stateful-operator-verifier
  - name: retro
    owner: stateful-operator-architect
---

# Stateful operator development workflow

## Scope

This workflow governs development of stateful operators on the GFV stack:

- gluten-flink planner: translating Flink plans and expressions into Velox plans for stateful operators
- gluten-flink runtime: operator execution, state access, watermark handling, and data bridging
- velox experimental stateful: the C++ stateful operator framework, state storage, and keyed execution
- velox4j: the Java/JNI bridge that carries stateful semantics across the language boundary

Large-scale velox upstream synchronization is out of scope unless the user explicitly authorizes it and defines a separate verification boundary.

## Agents

| Agent | Role |
|---|---|
| stateful-operator-orchestrator | schedules stages, runs gates, pauses at user gates, arbitrates disputes; never implements |
| stateful-operator-architect | owns the SPEC, the design, and the final summary |
| stateful-operator-developer | owns implementation, self-verification, and PR preparation |
| stateful-operator-reviewer | owns all review gates: SPEC review, design review, code review, final acceptance |
| stateful-operator-verifier | owns verification: unit tests, end-to-end runs, regression checks |

## Preconditions

Environment readiness is a CLI concern, not an agent stage. Before the task starts, the orchestrator runs `gfvbot env` in the target project; missing dependencies hand over to `gfvbot env-init`, missing source repos to `gfvbot clone`. The task enters the spec stage once the scan passes or the user accepts the gaps.

## Stage model

| Stage | Owner | Gate | Key artifacts |
|---|---|---|---|
| spec | architect | SPEC review approved by reviewer | architect/SPEC.md, reviewer/SPEC_REVIEW.md |
| design | architect | design review approved, no conflict with SPEC | architect/DESIGN.md, reviewer/DESIGN_REVIEW.md |
| implement | developer | code review pass | developer/IMPLEMENTATION.md, reviewer/CODE_REVIEW.md |
| verify | verifier | acceptance pass against SPEC acceptance criteria | verifier/VERIFY.md, reviewer/REVIEW_GATE.md |
| retro | architect | all artifacts archived | developer/PR.md, architect/SUMMARY.md, RETROSPECTIVE.md |

All artifact paths are relative to `tmp/<task-name>/` under the target project root; `<task-name>` is a stable short identifier chosen at task start.

## Stage details

### Spec

The architect turns the task description into a specification contract, driven by the plugin's SPEC template. The SPEC covers scope and goals, interface specification, behavior specification, acceptance criteria, a feasibility assessment, and the verification plan. The feasibility assessment is the first section: whether the velox C++ side supports the target semantics, how Flink operator semantics map to velox semantics (exact match, partial match, or compensation required), what existing code can be reused, which layers are affected, and one of the conclusions `feasible`, `feasible with constraints`, `feasible with upstream dependency`, or `not feasible`.

Gate: the reviewer signs SPEC_REVIEW.md with `approve`, `approve with changes`, or `reject`. A `not feasible` conclusion terminates or degrades the task. `reject` sends the architect back to revise the SPEC (new version file).

### Design

The architect produces a design within the approved SPEC: problem statement, scope and non-goals, impacted modules and files, class and API changes, execution and data flow, compatibility and regression risks, and the test strategy. The design cites concrete paths, class names, and commands; generic descriptions that could apply to any project are not acceptable.

Gate: the reviewer signs DESIGN_REVIEW.md. `reject` returns to design revision; `approve with changes` requires the changes be merged into DESIGN.md before implementation starts. Approval pauses at user gate 1.

### Implement

The developer implements per the design, self-compiles, formats, and writes unit tests. Every new or modified production file must have unit-test coverage of the normal path and boundary conditions; tests must run standalone. The developer records actual changes grouped by module, deviations from the design with reasons, key behavior changes, the list of new tests, and test run results in IMPLEMENTATION.md.

Gate: the reviewer signs CODE_REVIEW.md. The review must include a modification-scope compliance check against the SPEC and design impact list, and a unit-test coverage check; missing tests are a required-level issue. `fail` returns to the developer; any fix must pass code review again before verification.

### Verify

The verifier runs the layered verification: unit tests, end-to-end runs against the acceptance criteria, and regression checks on shared components. VERIFY.md records every command with its result, the coverage claims, performance and regression status, and — for each failure — the symptom, full error log, reproduction steps, environment, and a first-pass analysis, so the developer can fix without re-asking for context.

Verification verdicts are `pass` or `fail` only. The verifier never grants a pass by attributing a failure to a pre-existing issue or an environment limit; attribution is judged by the orchestrator and the user. A new operator must have at least one passing end-to-end case covering its core function. A Flink job counts as succeeded only when it reaches FINISHED.

Gate: the reviewer signs REVIEW_GATE.md, checking each SPEC acceptance criterion against VERIFY.md. `fail` returns to the developer; the fix must pass code review and verification again. Acceptance approval pauses at user gate 3.

### Retro

The developer prepares PR.md (documentation updates, commit plan, PR description, pre-merge checklist). The architect produces SUMMARY.md: final scope, approved deviations from the design, review verdicts across stages, verification coverage, remaining risks, and follow-up suggestions. Every participating agent writes a RETROSPECTIVE.md listing mistakes, lessons, and process suggestions. The final design document is archived into the target project's own documentation tree; the specifics follow the target project's conventions.

## Allowed regressions and forbidden jumps

The stage sequence is strictly serial. The only allowed loops are:

- spec → reviewer rejects → spec (revise, new version file)
- design → reviewer rejects → design (revise, new version file)
- implement → code review fails → implement (fix, self-compile, re-review)
- implement → verification fails → implement (fix, single-point self-verification, code review, verify again)
- implement → acceptance fails → implement (fix, code review, verify, acceptance again)
- any stage → docs-search lookups → same stage

Forbidden jumps, without exception:

- from spec (or feasibility) directly into implementation
- from design directly into implementation without design review approval
- from implementation directly into verification without code review pass
- from implementation or verification directly into retro
- from acceptance directly into retro without user gate 3 confirmation
- skipping any user gate

## Artifact contract

Artifacts under `tmp/<task-name>/` are the single source of truth across agents; verbal conclusions do not exist until written into an artifact. Later stages read artifacts, not chat history.

```text
tmp/<task-name>/
  TASK_STATE.md
  architect/    SPEC.md, DESIGN.md, SUMMARY.md, RETROSPECTIVE.md
  developer/    IMPLEMENTATION.md, PR.md, RETROSPECTIVE.md
  reviewer/     SPEC_REVIEW.md, DESIGN_REVIEW.md, CODE_REVIEW.md, REVIEW_GATE.md
  verifier/     VERIFY.md, RETROSPECTIVE.md
```

Version management: never overwrite an existing artifact. A reworked stage produces a versioned file (DESIGN_2.md, CODE_REVIEW_2.md, and so on); the orchestrator names the target file explicitly when routing rework. When a DESIGN went through multiple versions and was approved, the architect produces DESIGN_FINAL.md — a self-contained merge of all accepted corrections, with no references to earlier versions — and later stages reference the final file.

TASK_STATE.md is the context-recovery anchor. The orchestrator maintains it at every stage transition: task description, current stage, per-stage status, decisions, user constraints, known risks. Every agent reads it on startup and after context compaction.

Command-output archiving: long-running commands (compiles, test runs, cluster operations) redirect or tee their output to `tmp/logs/<task-name>/cmd-outputs/` with descriptive names. Before re-running a command, read the archive; re-run only when the inputs changed.

## User gates

Three pauses are mandatory and cannot be switched off:

| Gate | Position | Trigger |
|---|---|---|
| 1 | after design review approval | before implementation starts |
| 2 | after code review pass | before verification starts |
| 3 | after acceptance pass | before retro starts |

At each pause the orchestrator notifies the user with the artifact paths and waits. Questions or change requests raised by the user at a pause are routed to the owning agent for investigation and response; the orchestrator does not answer technical questions itself. If the user's input changes an artifact, the affected review re-runs from that stage: a design change re-enters design review, a code change re-enters code review and verification.

## Cross-cutting discipline

Context window control: read large source files in segments; locate code by search first, then read the exact ranges. Review agents read by need, not by whole files. The orchestrator keeps mandatory-reading lists short.

Dialectical review handling: the architect and developer verify reviewer feedback against actual code and design before acting on it. Correct feedback is accepted and fixed; incorrect feedback is answered with concrete evidence — file paths, line numbers, design sections. Dismissal without evidence, and deferral excuses like "later" or "out of scope", are forbidden; genuine scope disputes go to the orchestrator.

Agent reuse: the orchestrator reuses the existing same-named agent before spawning a new one, so context accumulates instead of resetting.
