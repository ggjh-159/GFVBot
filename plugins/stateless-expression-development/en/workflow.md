---
scheduler: stateless-expression-orchestrator
stages:
  - name: spec
    owner: stateless-expression-architect
  - name: design
    owner: stateless-expression-architect
  - name: implement
    owner: stateless-expression-developer
  - name: verify
    owner: stateless-expression-verifier
  - name: retro
    owner: stateless-expression-architect
---

# Stateless expression development workflow

## Scope

Covers one Flink scalar expression end to end across the GFV stack: the velox C++ implementation registered under the flinksql namespace, the gluten planner mapping, and the test pyramid (velox C++ unit tests, velox4j call-chain tests, lightweight e2e, full dual-run e2e). Out of scope: stateful operators, aggregate functions, performance tuning (other plugins own those).

Standing rules for every task:

- The runtime path is registered under `velox/functions/flinksql/` — spark/presto registrations are semantic references only, never the runtime implementation.
- Expression implementations prefer reusing existing velox libraries/classes, including existing function implementations — when semantics match, the flinksql registration references them directly, no rewrite needed; self-write only when reuse does not hold (no such facility, or the semantic comparison diverges).
- Modifying existing expression implementations is forbidden — behavior, signature, and structure all stay untouched; divergent semantics go through extension or addition only (new overloads, new registration entries, new files); reusing existing code directly is allowed.

## Agents

| Agent | Role |
|---|---|
| stateless-expression-orchestrator | schedules stages, runs gates, pauses at user gates; never implements or reviews |
| stateless-expression-architect | owns SPEC and DESIGN: velox survey, semantic comparison, flinksql registration design, coverage matrices |
| stateless-expression-developer | owns implementation: code, build, unit tests, lightweight e2e self-check |
| stateless-expression-reviewer | owns the three audit gates: design audit, code audit, result audit |
| stateless-expression-verifier | owns full dual-run e2e: SQL inventory, changelog fold comparison, TEST_REPORT |

## Running topology

The main session advances the workflow leg by leg, one leg = advancing from the current state to the next stop point (user gate, blocker, or full completion):

- The main session calls the orchestrator in the foreground and waits for its return; the orchestrator likewise makes only foreground Agent tool calls to owners and reviewers — `run_in_background` is forbidden, because background subtasks are reaped the moment their parent agent returns, which amounts to silent disposal; degrading to an OS subprocess plus polling waits is forbidden, because zombie processes get misjudged as alive by `kill -0`. When foreground Agent calls are unavailable, return and report immediately — never improvise a substitute to keep running.
- Dispatch leaves a trace: the dispatch intent (to whom, expected artifact) lands as one line in `PROGRESS.md` before dispatching; recovery breakpoints and silence detection both key off it; the orchestrator writes the next action into `TASK_STATE.md` before every return.
- The orchestrator returns at stop points: at user gates it brings back the decision-point checklist, at blockers the blocker report, and the main session relays them to the user; once user replies land in `USER_GATES.md`, the main session wakes the orchestrator again to continue. The orchestrator does not wait for user replies inside its turn.
- The prompt waking the orchestrator carries the task description, the target project root, and the advancement goal for this leg; on wake the orchestrator reads `TASK_STATE.md` first to recover. Cross-leg continuity is carried only by TASK_STATE.md and the task artifacts, never by agent-instance survival.
- The watchdog is a main-session duty — nobody checks while the orchestrator is not running: the main session uses a scheduled task every 15–20 minutes to check the update times of PROGRESS.md and TASK_STATE; silence past the threshold is reported to the user with intervention (inquiry or redispatch); every status line ends with "next check around HH:MM" so the silence boundary stays predictable; overnight and other cross-session scenarios require durable scheduling or user-side external monitoring — session-level timers vanish when the session closes.

## Preconditions

Environment readiness (repos cloned, toolchain installed, cluster built) is a CLI concern, not an agent stage: `gfvbot env`, `gfvbot env-init`, `gfvbot clone`, then the flink-velox-build skill deploys jars and starts the cluster. The workflow assumes a working GFV cluster and a native Flink cluster for dual runs.

## Stage model

| Stage | Owner | Gate | Key artifacts |
|---|---|---|---|
| spec | architect | — | SPEC.md |
| design | architect | design audit PASS + user gate 1 | DESIGN.md |
| implement | developer | code audit PASS + user gate 2 | IMPLEMENTATION.md, PR.md |
| verify | verifier | result audit PASS + user gate 3 | TEST_REPORT.md |
| retro | architect | — | SUMMARY.md, upstream/ drafts (when involved) |

## Stage details

### Spec

The architect fills the SPEC template (`templates/spec.md`): task info, the semantic baseline pinned to the function's card under `docs/gfvbot/shared/flink-expressions/` (signature, return type, NULL behavior, edge behavior — the card is the single source of truth), goal/scope, acceptance criteria, verification plan. Small by design; ambiguity here poisons everything downstream.

### Design

The architect fills the DESIGN template (`templates/design.md`). Mandatory movements:

1. Velox survey: read the card's "Velox implementation" section, then verify in the velox source (registration name, implementation file). Conclusion per option: reuse-as-reference, migrate to flinksql, rewrite (semantic mismatch), or new implementation.
2. Semantic comparison table: NULL handling, empty input, out-of-range/illegal arguments, type matrix, return precision, function-specific dimensions — any mismatch forbids direct reuse.
3. flinksql registration design (name, files, registration method, explicit signatures, CMake) per the flink-velox-flinksql-registration skill.
4. Gluten mapping design (RexCallConverterFactory entry; custom converter or direct name mapping).
5. Typography and content: follow the header disciplines — bullets, one fact + anchor per bullet, at most two lines, multi-ruling conclusions as a ruling list, no prose walls; core directions and key points only, with the agent's search/thinking process left out.
6. Unit-test coverage matrix, e2e coverage matrix (each e2e case is one SQL file with fixed input), special cases, risks.

Gate: the reviewer produces DESIGN_AUDIT (audit-report template, section A: scheme soundness, every supporting claim re-verified, coverage completeness, typography and content discipline). Verdict vocabulary: pass / fail — nothing else; a fail must carry concrete audit opinions; sub-standard typography (prose walls, anchor-less bullets) or process narration (agent search/thinking steps) also fails, with rework limited to re-layout and dropping the process narration — conclusions and key points stay unchanged. Only after pass does user gate 1 release implementation.

### Implement

The developer codes per the approved design: velox function + flinksql registration + CMake + unit tests, velox4j call-chain tests (EvaluationTest-style harness, FLINK preset), gluten mapping entry. Build and deploy only via the flink-velox-build skill (never skip the C++ build); unit tests only via flink-velox-unit-test; then a lightweight e2e self-check (self-constructed input, print sink, verify script) on the GFV cluster. Records everything in IMPLEMENTATION.md, including any change beyond the design's impact list (out-of-scope changes are a critical audit finding). Before delivery, prepares PR.md per the PR template (`templates/pr.md`): commit plan, PR description, pre-merge checklist.

Gate: the reviewer produces CODE_AUDIT (section B: design consistency, documentation synced with implementation, security, unit-test completeness vs the design matrix, code format, simpler/more efficient alternatives, redundancy/extensibility/readability). Pass + user gate 2 releases delivery.

### Verify

The verifier builds the full SQL inventory from the design's e2e matrix: fixed filesystem input, print sink, one SQL per case. Each case runs on native Flink and on GlutenFlink; outputs are folded from changelog (+I/-U/+U/-D) back to final result sets and compared exactly — no extra rows, no missing rows, no field mismatches; a job counts as passed only at FINISHED. Regression: representative cases of already-mapped expressions must stay identical. Cases and evidence land in the project-root `e2e/` evidence tree with the full-result rollup in `e2e/verify/RESULTS.md`; TEST_REPORT.md cites their paths and conclusions — all per the flink-velox-e2e-verify skill.

Gate: the reviewer produces RESULT_AUDIT (section C: unit tests all passed, test scope matches the design matrices, e2e results and regression). Pass + user gate 3 closes the task.

### Retro

When the changes touch the velox/velox4j/gluten repos, the developer prepares community drafts per the routing rules in `docs/gfvbot/shared/templates/upstream-contribution/`: one PR draft per changed repo, at most one issue draft per expression (gluten templates when the gluten repo changed, otherwise velox/velox4j templates), placed under `upstream/`, filed only after final user confirmation — agents never auto-submit issues or PRs.

The architect archives: SUMMARY.md (what was delivered, deviations from design, open issues, whether any lesson is worth distilling into the plugin's skills/docs — with a distillation suggestion when yes), TASK_STATE.md updated to closed.

## Allowed regressions and forbidden jumps

Allowed: fail audit → rework the target artifact → re-audit. Artifacts are snapshots: rework **refreshes the existing file in place** (`DESIGN.md`, `DESIGN_AUDIT.md`) — no version suffixes, no old copies left behind; round history is carried by the TASK_STATE gate log, one appended line per round. Verify failure traced to implementation → back to implement (with a TASK_STATE note); traced to design → back to design.

Forbidden: implementing before the design audit passes; running full e2e before the code audit passes; declaring completion with any audit unpassed or any user gate skipped; treating "compile passes" as "verified".

## Artifact contract

The artifacts under `tasks/<task-name>/` are the single source of truth shared across agents; a verbal conclusion does not exist until written into an artifact. Later stages read artifacts, not chat history.

Artifact structure: templated artifacts (SPEC/DESIGN/IMPLEMENTATION/PR/TEST_REPORT/audit reports/upstream drafts) keep their H1/H2 heading sets and numbering style verbatim against the corresponding template — nothing added, deleted, or renamed. The owner self-checks structure before writing; the reviewer structure-checks first at every audit, and a mismatch is a HIGH that blocks, returned with "documentation" attribution (re-layout only, technical content untouched).

Typography discipline (applies to every artifact in the task tree, checked at every audit): one fact per bullet, never chaining a second fact with ";"; table cells hold facts and anchors only, at most two lines, with reasoning moved to its own line; paragraphs are single-line flowing text without hard wraps. Horizontal rework coverage: when an artifact is returned for defect X, the orchestrator must scan all artifacts presented at the same gate and all existing task-tree artifacts for the same X and route the fixes together — fixing only the named copy does not count as done.

```text
tasks/<task-name>/
  TASK_STATE.md                  cross-agent state anchor
  USER_GATES.md                  per-round appended record of user-gate decision points and user replies
  PROGRESS.md                    intra-stage progress heartbeat: one appended line per owner milestone (time + agent + one sentence)
  architect/    SPEC.md  DESIGN.md  SUMMARY.md
  developer/    IMPLEMENTATION.md  PR.md
  reviewer/     DESIGN_AUDIT.md  CODE_AUDIT.md  RESULT_AUDIT.md
  verifier/     TEST_REPORT.md
  upstream/     community issue/PR drafts (per the shared upstream-contribution templates, filed after user confirmation)

tmp/<task-name>/dispatch/        dispatch briefs: one per dispatch (owner, target artifact, must-read anchors, discipline)
tmp/<task-name>/logs/            logs only: cmd-outputs/  jobs/ — never gate evidence, cleanable anytime
```

The e2e verification evidence tree lives at the project root, `e2e/{sql,data,out,verify}/`, not under the task directory — the SQL expresses verification scope, the data is the fixed input, outputs and diffs are run evidence, and the whole tree accretes across tasks into a regression bank. The full-result rollup lives in `e2e/verify/RESULTS.md` (refreshed in place each round); TEST_REPORT only cites its paths and conclusions.

TASK_STATE.md is the single recovery anchor: updated after every stage and every gate verdict. Artifacts are snapshots: rework refreshes existing files in place, and when the described object has changed (code rolled back and relanded, scope redefined) the affected artifacts must be refreshed before the next gate.

Progress tracking: at every milestone (key references read, a section drafted, a build finished) the owner agent appends one line to `PROGRESS.md`: time, agent, one sentence — timestamps must come from the measured output of `date +%F %T`; estimates are forbidden, and the "current time" carried in session context is a stale snapshot that likewise cannot serve as a basis. At dispatch the orchestrator says who takes the stage and what artifact is expected; when the owner returns it reports the outcome immediately and updates TASK_STATE.md; an owner returning without its artifact landed is a dispatch failure — verify and re-dispatch at once; intra-turn progress checking is the orchestrator's duty, cross-leg silence watchdogging is the main session's duty (see Running topology). The user can `tail -f tasks/<task-name>/PROGRESS.md` at any time.

Build/test command outputs are redirected into `tmp/<task-name>/logs/cmd-outputs/`, job submissions and crash captures into `tmp/<task-name>/logs/jobs/`; reports cite those paths as evidence, but logs themselves are transient — cleanable anytime, never deciding a gate.

## User gates

| Gate | Position | Trigger |
|---|---|---|
| 1 | after design audit passes | before any production code is written |
| 2 | after code audit passes | before delivery / full e2e begins |
| 3 | after result audit passes | before the task is declared complete |

At each pause the presentation and confirmation follow this mechanism:

- **Four-part presentation**: (1) a material list with reading order (every artifact under review **in full** — inline, or with path and reading guide; "full text provided" is a pre-release self-check item); (2) the decision-point checklist (see below); (3) reply guidance — the user answers only "confirm / object + opinion" per entry, and formatting the exchange is the main session's burden; (4) never cite list numbers that were not presented.
- **Decision-point checklist**: entries are drawn from the artifact under review and its template sections (e.g. after the design audit: the reuse decision, the mapping choice, coverage scope, risk acceptance); out-of-scope exclusions carry the same reporting duty as positive decisions — every exclusion comes with a reason and an evidence source. Each entry carries four elements — decision content (a decidable value; "reasonable/moderate" does not count), evidence source (which artifact section), attribution (which stage an objection returns to), and a confirm/object choice; entries take only what the artifacts already contain, never fields the artifacts left undefined.
- **Entry-by-entry interaction**: decision points are presented one at a time, the next only after the user answers — dumping the whole list at once is forbidden, and so is merging entries into groups to lower confirmation friction; reading an artifact in full and confirming entries are decoupled, and a user saying "show me the DESIGN" gets the full text separately.
- **Landing and release**: user replies are appended verbatim entry by entry to `USER_GATES.md`; the TASK_STATE gate row records the presentation form (full text / checklist only) for audit; release only when every entry is confirmed; contested entries route back to the owning agent for rework by attribution, the affected artifacts refresh in place, and the corresponding audit re-runs. The orchestrator does not answer technical questions itself.

## Cross-cutting discipline

Context economy: agents load only their bound skills/docs; grep before reading. The reviewer points, never patches. Audits are binary (pass/fail) with mandatory opinions on fail; HIGH findings block, MED/LOW advise. Changelog semantics and comparison standards follow the flink-velox-e2e-verify skill — the verifier never relaxes "exact match".

Agent dispatch: every dispatch is a fresh instance; the orchestrator names in the dispatch prompt which artifacts the owner must read and write this time; context recovery relies on TASK_STATE.md and the existing artifacts, never on instance survival.
