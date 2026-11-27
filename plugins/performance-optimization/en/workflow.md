---
scheduler: performance-orchestrator
stages:
  - name: spec
    owner: performance-analyst
  - name: design
    owner: performance-analyst
  - name: implement
    owner: performance-developer
  - name: verify
    owner: performance-verifier
  - name: retro
    owner: performance-analyst
---

# Performance optimization workflow

## Scope

This workflow governs the performance-optimization loop on the GFV stack — queries, operators, expressions, or aggregates that are already correct but fall short on performance:

- Baseline measurement: the GFV-vs-native-Flink throughput ratio under the fixed benchmark via the flink-velox-performance-verify skill (100M events, 50M tps, blackhole, p=1/4/8/16; native runs object-reuse false/true, GFV runs false only)
- Layered localization and attribution: starting from the ratios and the 8081 web UI (backpressure, operator state, throughput curves), attribute the bottleneck to the Java side (planner translation, data bridging), the JNI boundary (serialization, Arrow whole-batch passthrough), or the velox C++ side (operators, expressions, aggregate kernels)
- Optimization: changes per the plan, recompiled and redeployed
- Re-measurement and regression: the same matrix re-run for the ratios, plus the query set through the flink-velox-e2e-verify correctness regression

Feature development of new operators, functions, or aggregates is out of scope — it belongs to the stateful-operator-development, stateless-expression-development, and aggregate-function-development plugins respectively. Tool-level profiling (perf/async-profiler/flamegraph) has no consolidated skill in the repo yet: this workflow's design stage uses only grounded means, and when tool-level profiling is needed it is marked "skill to be consolidated" in the limitations list — commands are never invented.

Iron rules of this scenario: GFV must not run `pipeline.object-reuse=true` (it crashes; the skill script rejects it); benchmark parameters stay fully fixed across both stacks and all rounds, or the numbers are not comparable — confs are swapped in and restored by the skill, never hand-edited; optimization never changes query semantics, and every optimization round must pass the correctness regression; ratio verdicts are based on `e2e/perf/REPORT.md`, one column per native baseline (r0, r1).

## Agents

| Agent | Role |
|---|---|
| performance-orchestrator | schedules stages, runs gates, pauses at user gates, arbitrates disputes; never implements |
| performance-analyst | owns the SPEC (including baseline measurement), layered localization and the optimization plan, and the final summary |
| performance-developer | owns implementing the optimization, self-verification, and PR preparation |
| performance-reviewer | owns all review gates: SPEC review, design review, code review, final acceptance |
| performance-verifier | owns verification: ratio re-measurement, correctness regression, unit tests |

## Running topology

The main session advances the workflow leg by leg, one leg = advancing from the current state to the next stop point (user gate, blocker, or full completion):

- The main session calls the orchestrator in the foreground and waits for its return; the orchestrator likewise makes only foreground Agent tool calls to owners and reviewers — `run_in_background` is forbidden, because background subtasks are reaped the moment their parent agent returns, which amounts to silent disposal; degrading to an OS subprocess plus polling waits is forbidden, because zombie processes get misjudged as alive by `kill -0`. When foreground Agent calls are unavailable, return and report immediately — never improvise a substitute to keep running.
- Dispatch leaves a trace: the dispatch intent (to whom, expected artifact) lands as one line in `PROGRESS.md` before dispatching; recovery breakpoints and silence detection both key off it; the orchestrator writes the next action into `TASK_STATE.md` before every return.
- The orchestrator returns at stop points: at user gates it brings back the decision-point checklist, at blockers the blocker report, and the main session relays them to the user; once user replies land in `USER_GATES.md`, the main session wakes the orchestrator again to continue. The orchestrator does not wait for user replies inside its turn.
- The prompt waking the orchestrator carries the task description, the target project root, and the advancement goal for this leg; on wake the orchestrator reads `TASK_STATE.md` first to recover. Cross-leg continuity is carried only by TASK_STATE.md and the task artifacts, never by agent-instance survival.
- The watchdog is a main-session duty — nobody checks while the orchestrator is not running: the main session uses a scheduled task every 15–20 minutes to check the update times of PROGRESS.md and TASK_STATE; silence past the threshold is reported to the user with intervention (inquiry or redispatch); every status line ends with "next check around HH:MM" so the silence boundary stays predictable; overnight and other cross-session scenarios require durable scheduling or user-side external monitoring — session-level timers vanish when the session closes.

## Preconditions

Environment readiness is a CLI concern, not an agent stage. Before the task starts, the orchestrator runs `gfvbot env` in the target project; missing dependencies hand over to `gfvbot env-init`, missing source repos to `gfvbot clone`. The task enters the spec stage once the scan passes or the user accepts the gaps. Before baseline measurement also confirm: total cluster slots (TM count x taskmanager.numberOfTaskSlots) >= the task's highest parallelism level, and both the native-Flink build and the GFV build can be deployed — the cluster is restarted on the other build between rounds via flink-velox-build.

## Stage model

| Stage | Owner | Gate | Key artifacts |
|---|---|---|---|
| spec | analyst | SPEC review approved by reviewer | architect/SPEC.md (with baseline ratios), reviewer/SPEC_REVIEW.md, `e2e/perf/REPORT.md` (baseline round) |
| design | analyst | design review approved, no conflict with SPEC | architect/DESIGN.md, reviewer/DESIGN_REVIEW.md |
| implement | developer | code review pass | developer/IMPLEMENTATION.md, commits/ walkthrough, reviewer/CODE_REVIEW.md |
| verify | verifier | acceptance pass against SPEC acceptance criteria | verifier/VERIFY.md, `e2e/perf/REPORT.md` (re-measurement), reviewer/REVIEW_GATE.md |
| retro | analyst | all artifacts archived | developer/PR.md, architect/SUMMARY.md, RETROSPECTIVE.md, upstream/ drafts (when involved) |

All artifact paths are relative to `tasks/<task-name>/` under the target project root; at task start `<task-name>` is taken from `<query-or-object>-<symptom>` in the task description as a kebab-case short identifier (e.g. `q17-throughput`) — never named after a dispatch action or stage description — and stays fixed for the whole task. The analyst's artifacts keep the `architect/` directory name so the artifact tree stays identical across plugins.

## Stage details

### Spec

The analyst turns the task description into a performance-target contract, driven by the plugin's `templates/spec.md`. Baseline measurement comes first: via the flink-velox-performance-verify skill, run native r0/r1 and gfv r0 across the parallelism levels under the fixed benchmark (100M events, 50M tps, blackhole), producing `e2e/perf/REPORT.md` — the SPEC cites its ratios and invents no numbers. The SPEC covers the feasibility assessment (can the baseline be measured in this environment: slots, deployable builds, restartable cluster; is the target realistic), scope and goals, the optimization target and its baseline ratios, targets and constraints (target ratio or throughput gain; the query set must not regress in correctness; benchmark parameters fixed; GFV runs reuse=false only), acceptance criteria, and the verification plan. The query set takes q0 as the throughput baseline plus the target queries, selected per `docs/gfvbot/shared/nexmark-queries.md`.

Gate: the reviewer signs SPEC_REVIEW.md with `pass` or `fail` — nothing else; baseline numbers must come from the actual `e2e/perf/REPORT.md` artifact, and an estimate or paraphrase is a `fail`. A `fail` sends the analyst back to revise the SPEC (refreshed in place, then re-reviewed).

### Design

The analyst produces the layered localization and optimization plan within the approved SPEC following `templates/design.md`: current state and localization evidence (the baseline ratios cited; per the "full-stack profile locates the bottleneck layer" principle in `docs/gfvbot/shared/architecture.md`, starting from backpressure, operator state, and throughput curves in the 8081 web UI and combining them with the execution map in `docs/gfvbot/shared/internals/`, attribute the bottleneck to the Java side, the JNI boundary, or the velox C++ side — every attribution carries evidence: ratios, web UI observations, source paths), attribution and plan (a plan comparison table: plan x expected gain x risk x change scope, plus the selected plan's essentials), impacted modules and files, test strategy (ratio re-measurement matrix, correctness regression set, unit tests), and risks and pending decisions. When tool-level profiling (perf/async-profiler/flamegraph) is needed, mark "skill to be consolidated" in the limitations list and state the question it is expected to answer — never invent commands. The design cites concrete paths, class names, and commands; generic descriptions that could apply to any project are not acceptable. Every conclusion carries a one-line basis, and pending decisions are ruled item by item at user gate 1 and written back in place.

Gate: the reviewer signs DESIGN_REVIEW.md with a binary `pass`/`fail` ruling; the review includes a complete localization evidence chain (every layer conclusion evidenced), grounded attribution, a complete plan comparison, an explicit correctness regression strategy, and typography discipline. A `fail` returns the design for revision with itemized revision opinions; the revision refreshes DESIGN.md in place and is re-reviewed. A pass pauses at user gate 1.

### Implement

The developer implements the optimization per the plan, self-compiles, passes the flink-velox-format skill's format check (hard pre-commit rule: no commit on a failing check, log archived under cmd-outputs), and updates or adds unit tests. Optimization never changes query semantics — a change touching the result path must have a matching correctness regression case. The developer records actual changes grouped by module, deviations from the design with reasons, key behavior changes, the list of new tests, test run results, and the scenario self-check in IMPLEMENTATION.md (filled per `templates/implementation.md`).

Gate: the reviewer signs CODE_REVIEW.md. The review must include the format machine check (flink-velox-format skill's check passed, log path cited in the report, any violation is a `fail`), a modification-scope compliance check against the SPEC and design impact list, a unit-test coverage check, a semantics-unchanged check (whether the optimization touches the result path without regression coverage), and a documentation-sync check (the changes, deviations, and test results stated in IMPLEMENTATION.md checked item by item against the code — a snapshot frozen before rework is required-level). A `fail` returns to the developer with each opinion tagged with its attribution; any fix must pass code review again before verification. After code review passes and before the user gate 2 presentation, the developer produces the commit walkthrough per the flink-velox-commit-walkthrough skill (directories per repo, one file per commit), presented at gate 2 for human review. Rework fixes for review opinions are amended into the commit that introduced the problem (the id regenerates), never added as separate fix commits — history may be rewritten only while the task branch is unpublished; the walkthrough files refresh in place (names carry no commit id; only a rebase that changes the order renumbers them).

### Verify

The verifier runs the layered verification: ratio re-measurement, correctness regression, unit tests. Ratio re-measurement follows the flink-velox-performance-verify skill with exactly the same matrix as the baseline (native r0/r1 and gfv r0, same parallelism levels, same fixed benchmark); `e2e/perf/REPORT.md` refreshes in place to the post-optimization data, and VERIFY.md records the before/after GFV/native ratios. Correctness regression follows the flink-velox-e2e-verify skill: the SPEC query set runs on both native Flink and GFV and is compared as folded final result sets — no regression allowed. Unit tests run via the flink-velox-unit-test skill. VERIFY.md records every command with its result, the coverage claims, ratio changes, regression status, and — for each failure — the symptom, full error log, reproduction steps, environment, and a first-pass analysis. VERIFY.md is filled per `templates/verify.md`; the coverage claim is one of four choices (build success/targeted tests/partial verification/full verification), ticked honestly.

Verification verdicts are `pass` or `fail` only: ratios short of the SPEC target, any query regressing in correctness, or any job not reaching FINISHED is a `fail`. The verifier never grants a pass by attributing a failure to a pre-existing issue or an environment limit; attribution is judged by the orchestrator and the user. The verifier never hand-edits the benchmark parameters in nexmark.yaml or flink-conf, and never bypasses the skill's rejection of GFV + reuse=true.

Gate: the reviewer signs REVIEW_GATE.md, checking each SPEC acceptance criterion (target ratios and no regression) against VERIFY.md and `e2e/perf/REPORT.md`. `fail` returns to the developer; the fix must pass code review and verification again. Acceptance approval pauses at user gate 3.

### Retro

The developer prepares PR.md (documentation updates, commit plan, PR description, pre-merge checklist). The PR description must say why: what the problem is and why this approach (alternatives considered, trade-offs) — a description that only lists what was done does not qualify and is sent back for rewrite. When the changes touch the velox/velox4j/gluten repos, the developer also prepares community drafts per the routing rules in `docs/gfvbot/shared/templates/upstream-contribution/`: one PR draft per changed repo, at most one issue draft per optimization topic (gluten templates when the gluten repo changed, otherwise velox/velox4j templates), placed under `tasks/<task-name>/upstream/`, filed only after final user confirmation — agents never auto-submit issues or PRs. The analyst produces SUMMARY.md: final scope, optimization outcome (ratio changes), approved deviations from the design, review verdicts across stages, verification coverage, remaining risks, follow-up suggestions, and whether lessons are worth distilling into the plugin's skills/docs (with a distillation suggestion when yes — when a localization technique is mature enough to reproduce, suggest consolidating it into a skill). Every participating agent writes a RETROSPECTIVE.md listing mistakes, lessons, and process suggestions. The final design document is archived into the target project's own documentation tree; the specifics follow the target project's conventions.

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
- into design without baseline ratios; signing acceptance without the correctness regression

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
  commits/      commit walkthrough: <repo>/<seq>-<slug>.md, directories per repo, one file per commit; the sequence follows commit order and is the review order (produced after code review passes, for human review at gate 2)

tmp/<task-name>/dispatch/        dispatch briefs: one per dispatch (owner, target artifact, must-read anchors, discipline)
tmp/<task-name>/logs/            logs only: cmd-outputs/  jobs/ — never gate evidence, cleanable anytime
```

Artifacts are initialized from templates: SPEC/DESIGN/IMPLEMENTATION/VERIFY/review reports use spec.md, design.md, implementation.md, verify.md, and review-report.md under the plugin's `templates/`; TASK_STATE/USER_GATES/PROGRESS/PR use the shared templates task-state.md, user-gates.md, progress.md, and pr.md under `docs/gfvbot/shared/templates/`; the review-report template is reused across the four gates, deleting the irrelevant sections each time. Templated artifacts keep their H1/H2 heading sets and numbering style verbatim against the template — nothing added, deleted, or renamed; the owner self-checks structure before writing, the reviewer structure-checks first at every review, and a mismatch is a `fail` returned with "documentation" attribution.

Typography discipline (applies to every artifact in the task tree, checked at every review): one fact per bullet, never chaining a second fact with ";"; table cells hold facts and anchors only, at most two lines, with reasoning moved to its own line; paragraphs are single-line flowing text without hard wraps. Horizontal rework coverage: when an artifact is returned for defect X, the orchestrator must scan all artifacts presented at the same gate and all existing task-tree artifacts for the same X and route the fixes together — fixing only the named copy does not count as done.

The performance-comparison evidence tree lives at the project root, `e2e/perf/{native,gfv}/`, not inside any task directory — captures are run evidence and the report is the ratio basis, accreting across tasks; `e2e/perf/REPORT.md` refreshes in place each round (once for the baseline round, once for the re-measurement round; the SPEC and VERIFY.md cite the ratios of their respective rounds with the round noted). The e2e verification evidence tree likewise lives at the project root, `e2e/{sql,data,out,verify}/`, with the full-result rollup in `e2e/verify/RESULTS.md`; VERIFY.md only cites its paths and conclusions.

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
- **Gate-2 addendum, per-commit confirmation**: the commit walkthrough files are listed line by line in sequence order — repo, commit short hash and title, `tasks/<task-name>/commits/<repo>/<file>.md` path — matching the IMPLEMENTATION.md coverage declaration entry for entry. The presentation proceeds commit by commit in sequence order: each file is first presented with a gist line (short hash, title, one-sentence change intent) for the user to verify the file matches the commit, then the file is reviewed and released one by one; gate 2 passes only after every commit is confirmed — preventing a walkthrough-file/commit mismatch from causing a wrong release.
- **Decision-point checklist**: entries are drawn from the artifact under review and its template sections (e.g. after the design review: bottleneck attribution, plan selection, target ratios, regression scope, risk acceptance); out-of-scope exclusions carry the same reporting duty as positive decisions — every exclusion comes with a reason and an evidence source. Each entry carries four elements — decision content (a decidable value; "reasonable/moderate" does not count), evidence source (which artifact section), attribution (which stage an objection returns to), and a confirm/object choice; entries take only what the artifacts already contain, never fields the artifacts left undefined.
- **Entry-by-entry interaction**: decision points are presented one at a time, the next only after the user answers — dumping the whole list at once is forbidden, and so is merging entries into groups to lower confirmation friction; reading an artifact in full and confirming entries are decoupled, and a user saying "show me the DESIGN" gets the full text separately.
- **Landing and release**: user replies are appended verbatim entry by entry to `USER_GATES.md`; the TASK_STATE gate row records the presentation form (full text / checklist only) for audit; once the decision points (gate 2: including the per-commit confirmations) are all confirmed, a closing question asks: whether the artifact under review is accepted **as a whole** and the next stage may start — a whole-artifact objection routes back to the owner by attribution, and the gate never releases mechanically just because every entry was confirmed; the closing answer lands in `USER_GATES.md` as well; contested entries route back to the owning agent for rework by attribution, the affected artifacts refresh in place, and the corresponding review re-runs from that stage. The orchestrator does not answer technical questions itself.

## Cross-cutting discipline

Context window control: read large source files in segments; locate code by search first, then read the exact ranges. Review agents read by need, not by whole files. The orchestrator keeps mandatory-reading lists short.

Dialectical review handling: the analyst and developer verify reviewer feedback against actual code and design before acting on it. Correct feedback is accepted and fixed; incorrect feedback is answered with concrete evidence — file paths, line numbers, design sections. Dismissal without evidence, and deferral excuses like "later" or "out of scope", are forbidden; genuine scope disputes go to the orchestrator.

Agent dispatch: every dispatch is a fresh instance; the orchestrator names in the dispatch prompt which artifacts the owner must read and write this time; context recovery relies on TASK_STATE.md and the existing artifacts, never on instance survival.
