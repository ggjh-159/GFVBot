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

Covers one Flink scalar expression end to end across the GFV stack: the velox C++ implementation registered under the flinksql namespace, the gluten planner mapping, and the test pyramid (unit tests, lightweight e2e, full dual-run e2e). Out of scope: stateful operators, aggregate functions, performance tuning (other plugins own those).

Standing rule for every task: the runtime path is registered under `velox/functions/flinksql/` — spark/presto registrations are semantic references only, never the runtime implementation.

## Agents

| Agent | Role |
|---|---|
| stateless-expression-orchestrator | schedules stages, runs gates, pauses at user gates; never implements or reviews |
| stateless-expression-architect | owns SPEC and DESIGN: velox survey, semantic comparison, flinksql registration design, coverage matrices |
| stateless-expression-developer | owns implementation: code, build, unit tests, lightweight e2e self-check |
| stateless-expression-reviewer | owns the three audit gates: design audit, code audit, result audit |
| stateless-expression-verifier | owns full dual-run e2e: SQL inventory, changelog fold comparison, TEST_REPORT |

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
5. Unit-test coverage matrix, e2e coverage matrix (each e2e case is one SQL file with fixed input), special cases, risks.

Gate: the reviewer produces DESIGN_AUDIT (audit-report template, section A: scheme soundness, every supporting claim re-verified, coverage completeness). Verdict vocabulary: pass / fail — nothing else; a fail must carry concrete audit opinions. Only after pass does user gate 1 release implementation.

### Implement

The developer codes per the approved design: velox function + flinksql registration + CMake + unit tests, gluten mapping entry. Build and deploy only via the flink-velox-build skill (never skip the C++ build); unit tests only via flink-velox-unit-test; then a lightweight e2e self-check (self-constructed input, print sink, verify script) on the GFV cluster. Records everything in IMPLEMENTATION.md, including any change beyond the design's impact list (out-of-scope changes are a critical audit finding).

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

tmp/<task-name>/logs/            logs only: cmd-outputs/  jobs/ — never gate evidence, cleanable anytime
```

The e2e verification evidence tree lives at the project root, `e2e/{sql,data,out,verify}/`, not under the task directory — the SQL expresses verification scope, the data is the fixed input, outputs and diffs are run evidence, and the whole tree accretes across tasks into a regression bank. The full-result rollup lives in `e2e/verify/RESULTS.md` (refreshed in place each round); TEST_REPORT only cites its paths and conclusions.

TASK_STATE.md is the single recovery anchor: updated after every stage and every gate verdict. Artifacts are snapshots: rework refreshes existing files in place, and when the described object has changed (code rolled back and relanded, scope redefined) the affected artifacts must be refreshed before the next gate.

Progress tracking: at every milestone (key references read, a section drafted, a build finished) the owner agent appends one line to `PROGRESS.md`: time, agent, one sentence. At dispatch the orchestrator says who takes the stage and what artifact to expect; when the owner returns it reports the outcome immediately and updates TASK_STATE.md; when PROGRESS.md stays silent too long it checks the artifacts and run records and re-dispatches if needed — progress awareness is the orchestrator's duty, not the user's. The user can `tail -f tasks/<task-name>/PROGRESS.md` at any time.

Build/test command outputs are redirected into `tmp/<task-name>/logs/cmd-outputs/`, job submissions and crash captures into `tmp/<task-name>/logs/jobs/`; reports cite those paths as evidence, but logs themselves are transient — cleanable anytime, never deciding a gate.

## User gates

| Gate | Position | Trigger |
|---|---|---|
| 1 | after design audit passes | before any production code is written |
| 2 | after code audit passes | before delivery / full e2e begins |
| 3 | after result audit passes | before the task is declared complete |

Each user gate runs as follows: the orchestrator presents the audit report together with a **key-decision checklist** for entry-by-entry confirmation. Checklist entries are drawn from the artifact under audit and its template sections (e.g. after the design audit: the reuse decision, the mapping choice, coverage scope, risk acceptance), each carrying four elements — decision content (a decidable value; "reasonable/moderate" does not count), evidence source (which artifact section), attribution (which stage an objection returns to), and a confirm/object choice; entries take only what the artifacts already contain, never fields the artifacts left undefined. User replies are appended verbatim entry by entry to `USER_GATES.md`; release only when every entry is confirmed; contested entries route back for rework by attribution, the affected artifacts refresh in place, and the corresponding audit reruns.

## Cross-cutting discipline

Context economy: agents load only their bound skills/docs; grep before reading. The reviewer points, never patches. Audits are binary (pass/fail) with mandatory opinions on fail; HIGH findings block, MED/LOW advise. Changelog semantics and comparison standards follow the flink-velox-e2e-verify skill — the verifier never relaxes "exact match".
