---
name: flink-velox-review-response
description: Manage the upstream interaction lifecycle across velox / velox4j / gluten — issue-first submission prep, multi-round review-comment triage and fix loop, post-merge cascade — with per-post human-confirmation gates on every outbound action.
---

# flink-velox-review-response

Three phases cover the full upstream journey of a change set: Phase A submission prep (issue first + PR chain), Phase B the review-comment loop (pull → triage → fix → push → reply → description sync), Phase C the post-merge cascade.

## When to use

- After a plugin's retro stage produced upstream drafts and the PRs are filed and under review.
- Ad hoc: a new review comment arrives on any open PR of velox / velox4j / gluten (the user says "PR #N has new comments").

## Discipline

1. **No outbound content without confirmation**: review replies / PR descriptions / issue comments are shown in full, item by item, and confirmed item by item before posting (the user posts by hand by default; agent-posting only under explicit authorization); pushes confirm the commit summary + diff stat first. See "Human gates".
2. **Reviewed commits are append-only**: rules in Stage 4.
3. **PR title prefix**: use `[FLINK][VL]` or `[GLUTEN-<id>][FLINK][VL]` — a bare `[FLINK]` triggers prestodb-ci's "Invalid link" false positive.
4. **PR description hygiene and dependency disclosure**: no PR description in any repo mentions personal fork names or GFV-related names; multi-repo changes must state companion PR links, the expected commit pairing, and the landing order — a missing dependency note is a standard reviewer deduction.
5. **Cascade order**: velox → velox4j → gluten; ref / hash / URL change together, then a build confirms. The codeload hash only exists for pushed commits — push velox before updating the pin (details in `references/dependency-cascade.md`).
6. **Semantic divergences go to the user** (the agent never decides); evidence-first comments get the experiment before the reply.
7. **Claims match the implementation**: description, reply, and code land together; later changes that invalidate the description must update it in sync (Stage 6 covers this — restated here as discipline).
8. **Process record**: each round's artifacts stay in the three directories under `tasks/<task-name>/upstream/review-response/` (archive / replies / descriptions) — the process record and the baseline for the next increment, never mixed with retro's issue/PR drafts.

## Phase A — submission prep

### Issue first

One change set (regardless of repo count) files exactly one issue, in the entry repo: gluten if the set touches gluten; velox if it touches only velox / velox4j; the repo itself for single-repo changes. The entry repo's PR closes the issue with `Fixes #<id>`; the other repos' PRs reference it as `issue: <repo>#<id>`.

### PR-chain order

File in dependency order: velox (the flinksql implementation is the root artifact) → velox4j (the pin pointing at that velox head) → gluten (CI routing to that pin). Before filing, check titles, descriptions, and pin inputs against Discipline 3/4/5. The user files the PRs by hand (framework rule: agents never auto-submit); after each filing the skill verifies the PR is reachable and confirms the next repo's pin input is ready.

## Phase B — the review-comment loop

### Stage 0 — access & environment readiness

- **Credential tiers**: query endpoints work anonymously (60 req/h — a single round fits); CI-log download and high-frequency polling need a PAT (`public_repo` scope suffices for public repos). Detection: `GITHUB_TOKEN` / `git credential fill` / `~/.netrc`.
- **If unsatisfied, run the guidance loop until it passes**: apply (Settings → Developer settings → Personal access tokens → classic) → configure, three ways (`export GITHUB_TOKEN` / `git config --global credential.helper store` / write `~/.netrc` — curl needs `--netrc-optional`, git does not read netrc) → re-verify with `curl -s --netrc-optional https://api.github.com/user | grep '"login"'` (401 = token not delivered or invalid; 403 = rate limit).
- **Environment readiness**: locate the workspace via `.gfvbot/env.json` (not mandatory) or the root's `repos/{velox,velox4j,gluten}` layout; the three repos cloned with correct remotes; JAVA_HOME / maven / cmake available; taskset uses a legal CPU range inside the container; velox4j without a cpp build tree uses the Java-only path `mvn install -Dexec.skip=true`.

### Stage 1 — pull & archive

`bin/pull-reviews.sh <owner/repo> <pr> [output-file]` pulls the three endpoints (reviews, line comments, conversation comments) and writes `tasks/<task-name>/upstream/review-response/archive/<repo>-pr<N>-review-archive.md`. The archive is **grouped by review** (state + body + that review's line comments with `file:line` anchors); standalone line comments and conversation comments follow in time order. Increment = diff against the existing archive; only new reviews / comments surface.

### Stage 2 — triage

Classify each new comment:

- **must-fix**: a code defect — fix, verify, push.
- **decision-needed**: a semantic divergence — compile options and evidence for the user to decide; either outcome needs test coverage.
- **evidence-first**: run the experiment first (source anchors, EXPLAIN, live runs), then answer with the evidence chain.
- **wording**: comment/wording-only fix.
- **suggestion / minor**: not necessarily code-free — judge item by item; adopt-and-fix if reasonable, otherwise state the reason in the reply.

### Stage 3 — fix

Before switching branches: stash unrelated WIP under a semantic name, pop on return (in multi-task parallel, list stashes first).

**Verification tiers** (chosen by semantic impact; the commands are the only entry):

- **L1 compile + format** (always): velox — `git add -A` first, then `make format-fix CHECK_BASE=gluten-20260829` (check.py rejects unstaged edits); velox4j `mvn spotless:apply` + `mvn test-compile -Dexec.skip=true`; gluten — from the gluten-flink root, `mvn spotless:apply -pl planner,ut` + `mvn install -pl planner -DskipTests`.
- **L2 unit tests** (hard gate; locally green before pushing):
  - velox C++: the `flink-velox-unit-test` skill's `bin/run_velox_test.sh velox_functions_flinksql_test`, expecting `100% tests passed`.
  - velox4j: `mvn test` (cpp-build + full suite) — exit=1 is expected (it aborts at a known pre-existing upstream failure); the pass criteria = `Successfully built velox4j-cpp.` appears + the follow-up `mvn surefire:test@flink-preset-tests` yields `Tests run: 6, Failures: 0`.
  - gluten: from the gluten-flink root, `mvn test -pl ut -am`, expecting exit=0 fully green; after velox C++ changes, first `mvn install -Dexec.skip=true` in velox4j to deploy the new `.so` into m2.
- **L3 e2e dual-run** (runtime semantic changes only): per the `flink-velox-e2e-verify` skill; stop the clusters when done.

### Stage 4 — commit & push

**Across review rounds, append-only** (line comments anchor on commit SHA + (path, line); one SHA rewrite breaks the anchor — outdated). Four rules:

- **Cross-round append**: a new review round's response = appended commits on top of existing history; commits the reviewer has already seen are never amended/rebased.
- **Within-round freedom**: intermediate commits of the current round's response, unseen by the reviewer, may be freely appended or squash-merged into one before pushing (force-with-lease overwrites only this round's own intermediate state, never reviewed history); before amending, confirm the target is not a merge commit.
- An advanced upstream baseline syncs via **merge** (a clean empty-diff merge commit); when a maintainer explicitly asks for a rebase, comply — authority over anchors.
- **Sync the fork before pushing**: `git fetch upstream && git merge upstream/<base>` (or GitHub's Sync fork button) — a fork behind upstream imports the conflict straight into the PR.

On push rejection (non-fast-forward), consult the rules above before any force-with-lease. **Track CI after pushing**: query `commits/{sha}/check-runs`; on failure, first judge whether this PR introduced it; self-attributed findings return to Stage 3.

### Stage 5 — reply

Open with @ the reviewer + thanks + itemized responses + commit references; per-triage templates in `references/reply-conventions.md`. The default organization is one consolidated reply; long or context-dependent points additionally get an inline reply on their line comment. When history moved (merge-based sync), attach the old → new commit mapping.

### Stage 6 — PR description sync

Check the description against the implementation: tested-section counts, the claim list, whether Discipline 4's dependency disclosure is still accurate (update pairing info after companion PRs merge). A claim that outlives its implementation is resolved one way or the other — cover it in code (preferred) or drop it; an inconsistent claim never stands. Descriptions ship via `PATCH /repos/{owner}/{repo}/pulls/{n}` (body replaced wholesale — fetch current, produce new, show the diff) or the web UI; the accompanying comment notes "PR description updated accordingly". Major rewrites keep an `.old.md` snapshot under `descriptions/`.

## Phase C — post-merge cascade

- **Merge confirmation**: PR state → merged; did the `Fixes #` issue auto-close.
- **Cascade actions** (see `references/dependency-cascade.md`): velox4j ref → upstream merge head, repo URL fork → upstream, hash recomputed from the upstream codeload; gluten's clone line switches to the upstream branch, pin to the merge head.
- **Cross-branch impact check**: after any repo merges, check whether other in-flight branches diverged from the advanced upstream; sync affected branches with **merge** (protecting their anchors).
- **Wrap-up**: mark the archive/ closed; keep fork branches.

## Human gates

| Action | Risk | Gate |
|---|---|---|
| Pull / archive / analyze (read-only) | none | free |
| `git push` | notifies reviewers, enters PR history | confirm commit summary + diff stat before pushing |
| Review replies / PR descriptions / issue comments | outbound, speaks for the author | **show full text item by item, confirm item by item before posting**; the user posts by hand by default, agent-posting (API) only under explicit authorization |

Artifacts land in three directories: reply drafts `replies/<repo>-pr<N>-reply.md` (refreshed each round), description updates `descriptions/<repo>-pr<N>-description.md` (old versions kept as `.old.md`) — both walk the gate; nothing ships unconfirmed.
