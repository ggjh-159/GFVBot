#!/usr/bin/env bash
# run-e2e.sh — end-to-end smoke of the installer in a disposable sandbox.
#
# Safety rails (learned the hard way):
#   1. every install/uninstall call carries an explicit --target under SANDBOX
#   2. SANDBOX must live under /tmp, otherwise the script refuses to run
#   3. fixtures are clearly marked E2E FIXTURE; the sandbox is removed on
#      success and kept for inspection on failure
#
# Sequence: repo copy + fixtures → L1 → dry-run → install A → install B →
# idempotent reinstall → source-update reinstall → uninstall A (shared kept) →
# uninstall B (territory reclaim, zero residue) → pre-existing CLAUDE.md case.

set -u
export GFVBOT_LANG=en   # assertions grep English messages; keep them stable
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"

PASS=0
FAIL=0
ok()  { PASS=$((PASS + 1)); echo "  ok: $*"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL: $*" >&2; }
a() {  # <desc> <cmd...>
  local desc=$1; shift
  if "$@" >/dev/null 2>&1; then ok "$desc"; else bad "$desc"; fi
}

SANDBOX=$(mktemp -d /tmp/gfvbot-e2e.XXXXXX)
case "$SANDBOX" in
  /tmp/*) : ;;
  *) echo "refusing to run: sandbox not under /tmp ($SANDBOX)" >&2; exit 1 ;;
esac
KEEP="yes"
cleanup() {
  if [ "$KEEP" = "yes" ] && [ "$FAIL" -eq 0 ]; then
    rm -rf "$SANDBOX"
  else
    echo "sandbox kept for inspection: $SANDBOX" >&2
  fi
}
trap cleanup EXIT

COPY="$SANDBOX/repo"
T="$SANDBOX/target-fresh"
TU="$SANDBOX/target-user"
mkdir -p "$COPY" "$T" "$TU"
cp -r "$REPO_ROOT/." "$COPY/"
rm -rf "$COPY/.git" "$COPY/tests/e2e"
cp -r "$HERE/fixtures/repo/." "$COPY/"

# --- L1 on the fixture-loaded copy -----------------------------------------
if bash "$COPY/tests/run-tests.sh" --fast >/dev/null 2>&1; then
  ok "L1 passes on fixture-loaded copy"
else
  bad "L1 fails on fixture-loaded copy"
fi

# --- dry-run must not touch the target --------------------------------------
a "dry-run: clean target" bash -c "
  TMP=\$(mktemp -d '$SANDBOX'/dry.XXXX) &&
  bash '$COPY/installer/install.sh' --plugin stateful-operator-development \
       --tool claude --target \"\$TMP\" --dry-run >/dev/null 2>&1 &&
  [ -z \"\$(ls -A \"\$TMP\")\" ]"

# --- first install via the thin entry (explicit --target) -------------------
bash "$COPY/plugins/stateful-operator-development/install.sh" claude --target "$T" >/dev/null 2>&1
anchor_ok() {
  [ "$(cat "$T/CLAUDE.md")" = "$(printf '<!-- gfvbot -->\n@.claude/gfvbot/index.md\n<!-- /gfvbot -->')" ]
}
a "install A: anchor exact" anchor_ok
a "install A: record exists" test -f "$T/.gfvbot/records/stateful-operator-development.claude.json"
a "install A: shared skill landed" test -f "$T/.claude/skills/flink-velox-build/SKILL.md"
a "install A: agent landed" test -f "$T/.claude/agents/stateful-operator-reviewer.md"
a "install A: docs+templates landed" test -f "$T/docs/gfvbot/stateful-operator-development/templates/spec.md"
a "install A: template zh pair landed" test -f "$T/docs/gfvbot/stateful-operator-development/templates/spec.zh.md"

# --- second plugin: shared dedup, index sections, anchor stable -------------
bash "$COPY/installer/install.sh" --plugin performance-optimization --tool claude --target "$T" >/dev/null 2>&1
a "install B: anchor unchanged (replace path)" anchor_ok
a "install B: index carries 2 sections" bash -c "grep -c 'gfvbot:plugin:' '$T/.claude/gfvbot/index.md' | grep -qx 4"
a "install B: shared skill not duplicated" bash -c "[ \$(ls -d '$T/.claude/skills/flink-velox-build'* | wc -l) = 1 ]"

# --- idempotent reinstall ----------------------------------------------------
bash "$COPY/installer/install.sh" --plugin stateful-operator-development --tool claude --target "$T" 2>&1 \
  | grep -q 'already installed' && ok "reinstall: skip" || bad "reinstall: skip"

# --- source update → UPDATE path, markers survive section replace ------------
echo "e2e-update-marker" >> "$COPY/plugins/performance-optimization/workflow.md"
bash "$COPY/installer/install.sh" --plugin performance-optimization --tool claude --target "$T" >/dev/null 2>&1
a "update: anchor exact after section replace" anchor_ok
a "update: new content in index" grep -q '^e2e-update-marker$' "$T/.claude/gfvbot/index.md"

# --- uninstall one: reference counting keeps shared content ------------------
bash "$COPY/installer/uninstall.sh" stateful-operator-development --target "$T" >/dev/null 2>&1
a "uninstall A: shared skill kept (refcount)" test -f "$T/.claude/skills/flink-velox-build/SKILL.md"
a "uninstall A: own files gone" test ! -e "$T/.claude/skills/stateful-operator-codegen"
a "uninstall A: docs dir pruned" test ! -e "$T/docs/gfvbot/stateful-operator-development"
a "uninstall A: anchor intact" anchor_ok
a "uninstall A: index down to 1 section" bash -c "grep -c 'gfvbot:plugin:' '$T/.claude/gfvbot/index.md' | grep -qx 2"

# --- uninstall last: territory reclaim, zero residue --------------------------
bash "$COPY/installer/uninstall.sh" performance-optimization --target "$T" >/dev/null 2>&1
a "reclaim: .claude gone" test ! -e "$T/.claude"
a "reclaim: docs gone" test ! -e "$T/docs"
a "reclaim: .gfvbot gone" test ! -e "$T/.gfvbot"
a "reclaim: installer-created entry removed" test ! -e "$T/CLAUDE.md"
a "reclaim: zero residue" bash -c "[ -z \"\$(ls -A '$T')\" ]"

# --- pre-existing user CLAUDE.md survives the full cycle ---------------------
printf 'user content line\n' > "$TU/CLAUDE.md"
bash "$COPY/installer/install.sh" --plugin performance-optimization --tool claude --target "$TU" >/dev/null 2>&1
a "user entry: anchor + user content coexist" bash -c "grep -q 'user content line' '$TU/CLAUDE.md' && grep -q '<!-- gfvbot -->' '$TU/CLAUDE.md'"
bash "$COPY/installer/uninstall.sh" performance-optimization --target "$TU" >/dev/null 2>&1
a "user entry: anchor removed, content kept" bash -c "grep -q 'user content line' '$TU/CLAUDE.md' && ! grep -q 'gfvbot' '$TU/CLAUDE.md'"

# --- opencode lifecycle (second verified tool) ---------------------------------
TO="$SANDBOX/target-opencode"
mkdir -p "$TO"
bash "$COPY/installer/install.sh" --plugin performance-optimization --tool opencode --target "$TO" >/dev/null 2>&1
a "opencode: index landed" test -f "$TO/.opencode/gfvbot/index.md"
a "opencode: shared skill landed" test -f "$TO/.opencode/skills/flink-velox-build/SKILL.md"
a "opencode: agent landed" test -f "$TO/.opencode/agents/performance-reviewer.md"
a "opencode: AGENTS.md anchor carries index copy" grep -q 'gfvbot:plugin:performance-optimization' "$TO/AGENTS.md"
bash "$COPY/installer/uninstall.sh" performance-optimization --target "$TO" >/dev/null 2>&1
a "opencode: reclaim zero residue" bash -c "[ -z \"\$(ls -A '$TO')\" ]"

# --- multi-tool coexistence: one plugin under claude AND opencode --------------
TM="$SANDBOX/target-multi"
mkdir -p "$TM"
bash "$COPY/installer/install.sh" --plugin stateful-operator-development --tool claude --target "$TM" >/dev/null 2>&1
printf 'user content line\n' >> "$TM/CLAUDE.md"
bash "$COPY/installer/install.sh" --plugin performance-optimization --tool claude --target "$TM" >/dev/null 2>&1
bash "$COPY/installer/install.sh" --plugin stateful-operator-development --tool opencode --target "$TM" >/dev/null 2>&1
a "multi: three records (2 plugins, one dual-tool)" bash -c "[ \$(ls '$TM/.gfvbot/records' | wc -l) = 3 ]"
a "multi: claude index keeps both plugin sections" bash -c "grep -c 'gfvbot:plugin:' '$TM/.claude/gfvbot/index.md' | grep -qx 4"
a "multi: opencode index has its own copy" bash -c "grep -c 'gfvbot:plugin:' '$TM/.opencode/gfvbot/index.md' | grep -qx 2"
a "multi: shared skill in both layouts" bash -c "[ -f '$TM/.claude/skills/flink-velox-build/SKILL.md' ] && [ -f '$TM/.opencode/skills/flink-velox-build/SKILL.md' ]"
bash "$COPY/installer/uninstall.sh" stateful-operator-development --tool opencode --target "$TM" >/dev/null 2>&1
a "multi: opencode copy removed, claude side untouched" bash -c "[ ! -f '$TM/.opencode/gfvbot/index.md' ] && [ ! -e '$TM/.opencode/skills' ] && grep -c 'gfvbot:plugin:' '$TM/.claude/gfvbot/index.md' | grep -qx 4"
bash "$COPY/installer/uninstall.sh" stateful-operator-development --target "$TM" >/dev/null 2>&1
bash "$COPY/installer/uninstall.sh" performance-optimization --target "$TM" >/dev/null 2>&1
a "multi: full cycle ends clean, user file survives" bash -c "grep -q 'user content line' '$TM/CLAUDE.md' && ! grep -q 'gfvbot' '$TM/CLAUDE.md' && [ \"\$(ls -A '$TM')\" = 'CLAUDE.md' ]"

# --- project lang config survives territory reclaim ---------------------------
TC="$SANDBOX/target-lang"
mkdir -p "$TC"
( cd "$TC" && bash "$COPY/installer/bin/gfvbot" lang zh ) >/dev/null 2>&1
a "lang: project config written" test -f "$TC/.gfvbot/config"
bash "$COPY/installer/install.sh" --plugin performance-optimization --tool claude --target "$TC" >/dev/null 2>&1
bash "$COPY/installer/uninstall.sh" performance-optimization --target "$TC" >/dev/null 2>&1
a "lang: config survives reclaim" test -f "$TC/.gfvbot/config"
a "lang: records dir gone, only config left" test ! -e "$TC/.gfvbot/records"

# --- prompt subcommand: bilingual template, stdout only ------------------------
a "prompt: en template printed" bash -c "bash '$COPY/installer/bin/gfvbot' prompt stateful-operator-development | grep -q 'Task prompt'"
a "prompt: zh template via lang config" bash -c "cd '$TC' && env -u GFVBOT_LANG bash '$COPY/installer/bin/gfvbot' prompt stateful-operator-development | grep -q '任务prompt'"
a "prompt: unknown plugin fails" bash -c "! bash '$COPY/installer/bin/gfvbot' prompt no-such-plugin"
a "prompt: --task without --tool fails" bash -c "! bash '$COPY/installer/bin/gfvbot' prompt stateful-operator-development --task x"
a "prompt: --file writes template to file" bash -c "bash '$COPY/installer/bin/gfvbot' prompt stateful-operator-development --file '$TC/prompt.md' && grep -q 'Task prompt' '$TC/prompt.md'"
a "prompt: unwritable --file fails" bash -c "! bash '$COPY/installer/bin/gfvbot' prompt stateful-operator-development --file /nonexistent-dir/prompt.md"

# --- env subcommand: archive structure, --target, rescan ------------------------
bash "$COPY/installer/env.sh" --target "$TC" >/dev/null 2>&1
a "env: env.json valid json" jq -e . "$TC/.gfvbot/env.json"
a "env: repos placeholder" bash -c "jq -e '(.repos|keys|sort)==[\"flink\",\"gluten\",\"velox\",\"velox4j\"] and ([.repos[].ok]==[false,false,false,false])' '$TC/.gfvbot/env.json'"
a "env: five tools probed" bash -c "jq -e '(.\"tools\"|keys|sort)==[\"cmake\",\"g++\",\"gcc\",\"git\",\"mvn\"]' '$TC/.gfvbot/env.json'"
a "env: eight build tools probed" bash -c "jq -e '(.\"build_tools\"|keys|length)==8 and (.[\"build_tools\"]|to_entries|all(.value==true or .value==false))' '$TC/.gfvbot/env.json'"
a "env: twelve cpp deps probed" bash -c "jq -e '(.\"cpp_deps\"|keys|length)==12 and (.[\"cpp_deps\"]|to_entries|all(.value==true or .value==false)) and .\"cpp_deps\".libevent and .\"cpp_deps\".zlib' '$TC/.gfvbot/env.json'"
a "env: jdks 8 and 17 probed" bash -c "jq -e '(.\"jdks\"|keys|sort)==[\"17\",\"8\"]' '$TC/.gfvbot/env.json'"
a "env: four agents probed" bash -c "jq -e '(.\"agents\"|keys|sort)==[\"claude\",\"codex\",\"dsh\",\"opencode\"]' '$TC/.gfvbot/env.json'"
a "env: system facts recorded" bash -c "jq -e '.system.os and .system.cpu.cores and .system.mem_total_gb' '$TC/.gfvbot/env.json'"
a "env: stack flink/nexmark recorded" bash -c "jq -e '.stack.flink.ok==false or .stack.flink.ok==true' '$TC/.gfvbot/env.json'"
a "env: JAVA_HOME recorded" bash -c "jq -e '.env.JAVA_HOME.ok==false or .env.JAVA_HOME.ok==true' '$TC/.gfvbot/env.json'"
c1=$(jq -r .checked_at "$TC/.gfvbot/env.json"); sleep 1
bash "$COPY/installer/env.sh" --target "$TC" >/dev/null 2>&1
a "env: rescan refreshes archive" test "$c1" != "$(jq -r .checked_at "$TC/.gfvbot/env.json")"
bash "$COPY/installer/bin/gfvbot" env-init --target "$TC" >/dev/null 2>&1
a "env-init: runs the OS setup and re-archives" jq -e . "$TC/.gfvbot/env.json"

# --- clone subcommand: skip-existing, unknown repo, layout -----------------------
mkdir -p "$TC/repos/velox"
out=$(bash "$COPY/installer/bin/gfvbot" clone velox --target "$TC" 2>&1)
a "clone: existing repo skipped without network" bash -c "echo '$out' | grep -q 'skipping'"
a "clone: skipped repo recorded in env.json" bash -c "jq -e '.repos.velox.ok==true and (.repos.velox.path|endswith(\"/repos/velox\")) and .repos.velox.main_branch==\"gluten-0530\" and .repos.velox.url==.repos.velox.upstream and (.repos.velox.url|endswith(\"velox.git\"))' '$TC/.gfvbot/env.json'"
a "clone: env rescan keeps repo records" bash -c "bash '$COPY/installer/env.sh' --target '$TC' >/dev/null 2>&1 && jq -e '.repos.velox.ok==true and .repos.gluten.ok==false' '$TC/.gfvbot/env.json'"
a "clone: unknown repo rejected" bash -c "! bash '$COPY/installer/bin/gfvbot' clone no-such-repo 2>/dev/null"
a "clone: --fork without a value fails" bash -c "! bash '$COPY/installer/bin/gfvbot' clone velox --fork"
a "clone: usage lists --fork" bash -c "bash '$COPY/installer/bin/gfvbot' help | grep -q -- '--fork'"
a "clone: usage lists the subcommand" bash "$COPY/installer/bin/gfvbot" help | grep -q "gfvbot clone"

# --- clone failure path: retry, no partial dir, summary hint -------------------
sed -i "s#velox|https://github.com/bigo-sg/velox.git|gluten-0530|yes#velox|file://$SANDBOX/no-such.git|gluten-0530|yes#" "$COPY/installer/lib/common.sh"
TF="$SANDBOX/target-clonefail"
mkdir -p "$TF"
a "clone: failed clone retries" bash -c "
  GFVBOT_CLONE_TRIES=2 GFVBOT_CLONE_RETRY_SLEEP=0 \
  bash '$COPY/installer/bin/gfvbot' clone velox --target '$TF' 2>&1 | grep -q 'retrying in'"
a "clone: failed clone leaves no partial dir" test ! -e "$TF/repos/velox"
a "clone: failed repo not recorded in env.json" bash -c "! jq -e '.repos.velox.ok==true' '$TF/.gfvbot/env.json' 2>/dev/null"
a "clone: summary lists the failed repo" bash -c "
  GFVBOT_CLONE_TRIES=1 GFVBOT_CLONE_RETRY_SLEEP=0 \
  bash '$COPY/installer/bin/gfvbot' clone velox --target '$TF' 2>&1 | grep -q 'Re-run the same command'"

echo
echo "e2e: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
