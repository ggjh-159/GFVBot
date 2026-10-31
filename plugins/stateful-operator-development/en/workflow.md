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

## Running topology

The main session advances the workflow leg by leg, one leg = advancing from the current state to the next stop point (user gate, blocker, or full completion):

- The main session calls the orchestrator in the foreground and waits for its return; the orchestrator likewise makes only foreground Agent tool calls to owners and reviewers — `run_in_background` is forbidden, because background subtasks are reaped the moment their parent agent returns, which amounts to silent disposal; degrading to an OS subprocess plus polling waits is forbidden, because zombie processes get misjudged as alive by `kill -0`. When foreground Agent calls are unavailable, return and report immediately — never improvise a substitute to keep running.
- Dispatch leaves a trace: the dispatch intent (to whom, expected artifact) lands as one line in `PROGRESS.md` before dispatching; recovery breakpoints and silence detection both key off it; the orchestrator writes the next action into `TASK_STATE.md` before every return.
- The orchestrator returns at stop points: at user gates it brings back the decision-point checklist, at blockers the blocker report, and the main session relays them to the user; once user replies land in `USER_GATES.md`, the main session wakes the orchestrator again to continue. The orchestrator does not wait for user replies inside its turn.
- The prompt waking the orchestrator carries the task description, the target project root, and the advancement goal for this leg; on wake the orchestrator reads `TASK_STATE.md` first to recover. Cross-leg continuity is carried only by TASK_STATE.md and the task artifacts, never by agent-instance survival.
- The watchdog is a main-session duty — nobody checks while the orchestrator is not running: the main session uses a scheduled task every 15–20 minutes to check the update times of PROGRESS.md and TASK_STATE; silence past the threshold is reported to the user with intervention (inquiry or redispatch); every status line ends with "next check around HH:MM" so the silence boundary stays predictable; overnight and other cross-session scenarios require durable scheduling or user-side external monitoring — session-level timers vanish when the session closes.

## Preconditions

Environment readiness is a CLI concern, not an agent stage. Before the task starts, the orchestrator runs `gfvbot env` in the target project; missing dependencies hand over to `gfvbot env-init`, missing source repos to `gfvbot clone`. The task enters the spec stage once the scan passes or the user accepts the gaps.

## Stage model

| Stage | Owner | Gate | Key artifacts |
|---|---|---|---|
| spec | architect | SPEC review approved by reviewer | architect/SPEC.md, reviewer/SPEC_REVIEW.md |
| design | architect | design review approved, no conflict with SPEC | architect/DESIGN.md, reviewer/DESIGN_REVIEW.md |
| implement | developer | code review pass | developer/IMPLEMENTATION.md, reviewer/CODE_REVIEW.md |
| verify | verifier | acceptance pass against SPEC acceptance criteria | verifier/VERIFY.md, reviewer/REVIEW_GATE.md |
| retro | architect | all artifacts archived | developer/PR.md, architect/SUMMARY.md, RETROSPECTIVE.md, upstream/ drafts (when involved) |

All artifact paths are relative to `tasks/<task-name>/` under the target project root; `<task-name>` is a stable short identifier chosen at task start.

## Stage details

### Spec

The architect turns the task description into a specification contract, driven by the plugin's `templates/spec.md`. The SPEC covers scope and goals, interface specification, behavior specification, acceptance criteria, a feasibility assessment, and the verification plan. The feasibility assessment is the first section: whether the velox C++ side supports the target semantics, how Flink operator semantics map to velox semantics (exact match, partial match, or compensation required), what existing code can be reused, which layers are affected, and one of the conclusions `feasible`, `feasible with constraints`, `feasible with upstream dependency`, or `not feasible`. The assessment is checked item by item against the stateful operator implementation contract in `docs/gfvbot/shared/stateful-operator-implementation.md` (backend guarantees, state handle selection, lifecycle patterns). The feasibility analysis runs through the flink-velox-stateful-spec-analysis skill: two-tier determination (semantic mapping × infrastructure supply) with a matrix lookup for the four-way conclusion; task-level constraints only tighten, accompanying constraints are recorded item by item, and the material merges into the SPEC sections.

Gate: the reviewer signs SPEC_REVIEW.md with `pass` or `fail` — nothing else; a `fail` must carry concrete revision opinions. A `not feasible` conclusion terminates or degrades the task. A `fail` sends the architect back to revise the SPEC (refreshed in place, then re-reviewed).

### Design

The architect produces a design within the approved SPEC following `templates/design.md`: task and inputs (formula positioning), current-state survey (three-stage honest grading of the translation chain + reuse dispositions), contract matching (state handle selection, lifecycle pattern placement, non-keyed iron rule), impacted modules and files (velox/velox4j/gluten, three repos), execution and data flow (with the alignment list), checkpoint semantics, test strategy, risks checked against the pitfall table, limitations, and pending decisions. The design cites concrete paths, class names, and commands; generic descriptions that could apply to any project are not acceptable. Stateful operator designs take `docs/gfvbot/shared/stateful-operator-implementation.md` as their primary technical reference — the lifecycle hooks, the five backend-construction steps, the seven-step addInput pattern, and the pitfall list are matched item by item. Design material is produced through the flink-velox-stateful-design-analysis skill: mechanism-level semantic deepening, three-stage honest grading of the current state, reuse dispositions, the alignment list, limitations, and pending decisions; every conclusion carries a one-line basis, and pending decisions are ruled item by item at user gate 1 and written back in place.

Gate: the reviewer signs DESIGN_REVIEW.md with a binary `pass`/`fail` ruling; the review includes contract-matching completeness and typography discipline (spot-checked section by section against the artifact contract's quantified standards). A `fail` returns the design for revision with itemized revision opinions; the revision refreshes DESIGN.md in place and is re-reviewed. A pass pauses at user gate 1.

### Implement

The developer implements per the design, self-compiles, formats, and writes unit tests. Every new or modified production file must have unit-test coverage of the normal path and boundary conditions; tests must run standalone. The developer records actual changes grouped by module, deviations from the design with reasons, key behavior changes, the list of new tests, test run results, and the contract self-check in IMPLEMENTATION.md (filled per `templates/implementation.md`).

Gate: the reviewer signs CODE_REVIEW.md. The review must include a modification-scope compliance check against the SPEC and design impact list, a unit-test coverage check, and a documentation-sync check (the changes, deviations, and test results stated in IMPLEMENTATION.md checked item by item against the code — a snapshot frozen before rework is required-level); missing tests are a required-level issue. A `fail` returns to the developer with each opinion tagged with its attribution; any fix must pass code review again before verification.

### Verify

The verifier runs the layered verification: unit tests, end-to-end runs against the acceptance criteria, and regression checks on shared components. End-to-end runs follow the flink-velox-e2e-verify skill: cases and evidence land in the project-root `e2e/` evidence tree with the full-result rollup in `e2e/verify/RESULTS.md`; VERIFY.md cites their paths and conclusions. VERIFY.md records every command with its result, the coverage claims, performance and regression status, and — for each failure — the symptom, full error log, reproduction steps, environment, and a first-pass analysis, so the developer can fix without re-asking for context. VERIFY.md is filled per `templates/verify.md`; the coverage claim is one of four choices (build success/targeted tests/partial verification/full verification), ticked honestly.

Verification verdicts are `pass` or `fail` only. The verifier never grants a pass by attributing a failure to a pre-existing issue or an environment limit; attribution is judged by the orchestrator and the user. A new operator must have at least one passing end-to-end case covering its core function. A Flink job counts as succeeded only when it reaches FINISHED.

Gate: the reviewer signs REVIEW_GATE.md, checking each SPEC acceptance criterion against VERIFY.md. `fail` returns to the developer; the fix must pass code review and verification again. Acceptance approval pauses at user gate 3.

### Retro

The developer prepares PR.md (documentation updates, commit plan, PR description, pre-merge checklist). When the changes touch the velox/velox4j/gluten repos, the developer also prepares community drafts per the routing rules in `docs/gfvbot/shared/templates/upstream-contribution/`: one PR draft per changed repo, at most one issue draft per operator (gluten templates when the gluten repo changed, otherwise velox/velox4j templates), placed under `tasks/<task-name>/upstream/`, filed only after final user confirmation — agents never auto-submit issues or PRs. The architect produces SUMMARY.md: final scope, approved deviations from the design, review verdicts across stages, verification coverage, remaining risks, follow-up suggestions, and whether lessons are worth distilling into the plugin's skills/docs (with a distillation suggestion when yes). Every participating agent writes a RETROSPECTIVE.md listing mistakes, lessons, and process suggestions. The final design document is archived into the target project's own documentation tree; the specifics follow the target project's conventions.

## Allowed regressions and forbidden jumps

The stage sequence is strictly serial. The only allowed loops are:

- spec → reviewer rejects → spec (revise in place, re-review)
- design → reviewer rejects → design (revise in place, re-review)
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

Artifacts under `tasks/<task-name>/` are the single source of truth across agents; verbal conclusions do not exist until written into an artifact. Later stages read artifacts, not chat history.

```text
tasks/<task-name>/
  TASK_STATE.md                  cross-agent state anchor
  USER_GATES.md                  per-round appended record of user-gate decision points and user replies
  PROGRESS.md                    intra-stage progress heartbeat: one appended line per milestone (time + agent + one sentence)
  architect/    SPEC.md, DESIGN.md, SUMMARY.md, RETROSPECTIVE.md
  developer/    IMPLEMENTATION.md, PR.md, RETROSPECTIVE.md
  reviewer/     SPEC_REVIEW.md, DESIGN_REVIEW.md, CODE_REVIEW.md, REVIEW_GATE.md
  verifier/     VERIFY.md, RETROSPECTIVE.md
  upstream/     community issue/PR drafts (per the shared upstream-contribution templates, filed after user confirmation)

tmp/<task-name>/dispatch/        dispatch briefs: one per dispatch (owner, target artifact, must-read anchors, discipline)
tmp/<task-name>/logs/            logs only: cmd-outputs/  jobs/ — never gate evidence, cleanable anytime
```

Artifacts are initialized from the plugin templates: SPEC/DESIGN/IMPLEMENTATION/VERIFY/TASK_STATE/review reports use spec.md, design.md, implementation.md, verify.md, task-state.md, and review-report.md under `templates/` respectively, PR uses pr.md, and USER_GATES/PROGRESS use user-gates.md and progress.md; the review-report template is reused across the four gates, deleting the irrelevant sections each time. Templated artifacts keep their H1/H2 heading sets and numbering style verbatim against the template — nothing added, deleted, or renamed; the owner self-checks structure before writing, the reviewer structure-checks first at every review, and a mismatch is a `fail` returned with "documentation" attribution.

Typography discipline (applies to every artifact in the task tree, checked at every review): one fact per bullet, never chaining a second fact with ";"; table cells hold facts and anchors only, at most two lines, with reasoning moved to its own line; paragraphs are single-line flowing text without hard wraps. Horizontal rework coverage: when an artifact is returned for defect X, the orchestrator must scan all artifacts presented at the same gate and all existing task-tree artifacts for the same X and route the fixes together — fixing only the named copy does not count as done.

The e2e verification evidence tree lives at the project root, `e2e/{sql,data,out,verify}/`, not inside any task directory — the SQL expresses verification scope, outputs and diffs are run evidence, and the tree accretes across tasks into a regression bank. The full-result rollup lives in `e2e/verify/RESULTS.md` (refreshed in place each round); VERIFY.md only cites its paths and conclusions.

Snapshot management: artifacts are snapshots — rework **refreshes the existing file in place** (DESIGN.md, CODE_REVIEW.md, and so on), with no version suffixes and no old copies left behind; the orchestrator names the target artifact and section explicitly when routing rework. When the described object has changed (code rolled back and relanded, scope redefined), refresh the affected artifacts before entering the next gate. Round history is carried by the TASK_STATE gate records, one appended line per round.

TASK_STATE.md is the context-recovery anchor. The orchestrator maintains it at every stage transition: task description, current stage, per-stage status, decisions, user constraints, known risks. Every agent reads it on startup and after context compaction.

Progress tracking: the owning agent appends one line to `PROGRESS.md` at every milestone (key reference read, a section drafted, a build round finished): time, agent, one sentence — timestamps must come from the measured output of `date +%F %T`; estimates are forbidden, and the "current time" carried in session context is a stale snapshot that likewise cannot serve as a basis. On dispatch the orchestrator states who receives the work and what artifact is expected; when an owner returns, report immediately and update TASK_STATE.md; an owner returning without its artifact landed is a dispatch failure — verify and redispatch at once; intra-turn progress checking is the orchestrator's duty, cross-leg silence watchdogging is the main session's duty (see Running topology). The user can `tail -f tasks/<task-name>/PROGRESS.md` anytime to watch progress.

Command-output archiving: long-running commands (compiles, test runs) redirect or tee their output to `tmp/<task-name>/logs/cmd-outputs/` with descriptive names; job submissions and crash captures go to `tmp/<task-name>/logs/jobs/`. Before re-running a command, read the archive; re-run only when the inputs changed. Reports cite those paths as evidence, but logs themselves are transient — cleanable anytime, never deciding a gate.

## User gates

Three pauses are mandatory and cannot be switched off:

| Gate | Position | Trigger |
|---|---|---|
| 1 | after design review approval | before implementation starts |
| 2 | after code review pass | before verification starts |
| 3 | after acceptance pass | before retro starts |

At each pause the presentation and confirmation follow this mechanism:

- **Four-part presentation**: (1) a material list with reading order (every artifact under review **in full** — inline, or with path and reading guide; "full text provided" is a pre-release self-check item); (2) the decision-point checklist (see below); (3) reply guidance — the user answers only "confirm / object + opinion" per entry, and formatting the exchange is the main session's burden; (4) never cite list numbers that were not presented.
- **Decision-point checklist**: entries are drawn from the artifact under review and its template sections (e.g. after the design review: the semantic mapping approach, reuse decisions, feasibility constraints, test strategy, risk acceptance); out-of-scope exclusions carry the same reporting duty as positive decisions — every exclusion comes with a reason and an evidence source. Each entry carries four elements — decision content (a decidable value; "reasonable/moderate" does not count), evidence source (which artifact section), attribution (which stage an objection returns to), and a confirm/object choice; entries take only what the artifacts already contain, never fields the artifacts left undefined.
- **Entry-by-entry interaction**: decision points are presented one at a time, the next only after the user answers — dumping the whole list at once is forbidden, and so is merging entries into groups to lower confirmation friction; reading an artifact in full and confirming entries are decoupled, and a user saying "show me the DESIGN" gets the full text separately.
- **Landing and release**: user replies are appended verbatim entry by entry to `USER_GATES.md`; the TASK_STATE gate row records the presentation form (full text / checklist only) for audit; release only when every entry is confirmed; contested entries route back to the owning agent for rework by attribution, the affected artifacts refresh in place, and the corresponding review re-runs from that stage. The orchestrator does not answer technical questions itself.

## Cross-cutting discipline

Context window control: read large source files in segments; locate code by search first, then read the exact ranges. Review agents read by need, not by whole files. The orchestrator keeps mandatory-reading lists short.

Dialectical review handling: the architect and developer verify reviewer feedback against actual code and design before acting on it. Correct feedback is accepted and fixed; incorrect feedback is answered with concrete evidence — file paths, line numbers, design sections. Dismissal without evidence, and deferral excuses like "later" or "out of scope", are forbidden; genuine scope disputes go to the orchestrator.

Agent dispatch: every dispatch is a fresh instance; the orchestrator names in the dispatch prompt which artifacts the owner must read and write this time; context recovery relies on TASK_STATE.md and the existing artifacts, never on instance survival.
