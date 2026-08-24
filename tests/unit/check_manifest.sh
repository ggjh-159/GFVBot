#!/usr/bin/env bash
# check_manifest.sh — L1: plugin.json validity, declared-unit existence,
# frontmatter shape, naming, and manifest ↔ agent-binding union consistency.

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$TESTS_DIR/lib.sh"
ROOT="$(cd "$TESTS_DIR/../.." && pwd)"
PLUGINS_DIR="$ROOT/plugins"
SHARED_DIR="$ROOT/shared"

# scene prefix = plugin name minus the -development / -optimization suffix
scene_prefix() { local s="$1"; s="${s%-development}"; echo "${s%-optimization}"; }

for d in "$PLUGINS_DIR"/*/; do
  p=$(basename "$d")
  m="$d/plugin.json"
  echo "plugin: $p"

  if ! jq -e . "$m" >/dev/null 2>&1; then
    fail "plugin.json is not valid JSON"
    continue
  fi
  pass "plugin.json valid JSON"

  [ "$(jq -r '.name' "$m")" = "$p" ] && pass "name == directory name" || fail "name != directory name"
  [ -n "$(jq -r '.description // empty' "$m")" ] || fail "manifest description missing"
  [ -n "$(jq -r '.description_zh // empty' "$m")" ] || fail "manifest description_zh missing (bilingual descriptions are mandatory)"
  [ "$(jq -r '.workflow' "$m")" = "workflow.md" ] || fail "workflow field must be workflow.md"
  [ -f "$d/workflow.md" ] || fail "workflow.md missing"
  is_kebab "$p" && pass "plugin name kebab-case" || fail "plugin name not kebab-case: $p"

  # workflow.md frontmatter keys (values may still be empty placeholders)
  [ -n "$(fm_scalar "$d/workflow.md" scheduler)" ] || grep -q '^scheduler:' "$d/workflow.md" \
    && pass "workflow frontmatter declares scheduler" \
    || fail "workflow frontmatter missing scheduler key"
  grep -q '^stages:' "$d/workflow.md" || fail "workflow frontmatter missing stages key"

  sp=$(scene_prefix "$p")

  # --- plugin-owned units: existence, naming, scene prefix ---
  while IFS= read -r u; do
    [ -z "$u" ] && continue
    [ -f "$d/agents/$u.md" ] || fail "declared agent missing: agents/$u.md"
    grep -q '^name:' "$d/agents/$u.md" || fail "agent frontmatter missing name key: $u"
    grep -q '^description:' "$d/agents/$u.md" || fail "agent frontmatter missing description key: $u"
    grep -q '^skills:' "$d/agents/$u.md" || fail "agent frontmatter missing skills key: $u"
    grep -q '^docs:' "$d/agents/$u.md" || fail "agent frontmatter missing docs key: $u"
    case "$u" in "$sp"-*) pass "agent scene-prefixed: $u" ;; *) fail "agent not scene-prefixed ($sp-): $u" ;; esac
  done < <(jq -r '.agents[]? // empty' "$m")

  while IFS= read -r u; do
    [ -z "$u" ] && continue
    [ -d "$d/skills/$u" ] || fail "declared skill missing: skills/$u"
    case "$u" in "$sp"-*) : ;; *) fail "skill not scene-prefixed ($sp-): $u" ;; esac
  done < <(jq -r '.skills[]? // empty' "$m")

  while IFS= read -r u; do
    [ -z "$u" ] && continue
    [ -e "$d/docs/$u" ] || fail "declared doc missing: docs/$u"
  done < <(jq -r '.docs[]? // empty' "$m")

  while IFS= read -r u; do
    [ -z "$u" ] && continue
    [ -e "$d/templates/$u" ] || fail "declared template missing: templates/$u"
  done < <(jq -r '.templates[]? // empty' "$m")

  # --- shared declarations: existence ---
  for kind in skills docs templates; do
    while IFS= read -r u; do
      [ -z "$u" ] && continue
      [ -e "$SHARED_DIR/$kind/$u" ] || fail "declared shared $kind missing: shared/$kind/$u"
    done < <(jq -r ".shared.$kind[]? // empty" "$m")
  done

  # --- manifest ↔ agent-binding union consistency ---
  # agents may bind owned or shared units; the union of what agents bind must
  # equal what the manifest declares (own + shared), in both skills and docs
  for kind in skills docs; do
    mani=$(jq -r "[(.${kind}[]?), (.shared.${kind}[]?)] | unique | .[]" "$m")
    agent_union=""
    while IFS= read -r a; do
      [ -z "$a" ] && continue
      agent_union="$agent_union$(fm_list "$d/agents/$a.md" "$kind")"$'\n'
    done < <(jq -r '.agents[]? // empty' "$m")
    mani_sorted=$(printf '%s' "$mani" | LC_ALL=C sort -u)
    union_sorted=$(printf '%s' "$agent_union" | LC_ALL=C sort -u | sed '/^$/d')
    if [ "$mani_sorted" = "$union_sorted" ]; then
      pass "manifest $kind == union of agent bindings"
    else
      fail "$kind mismatch — manifest: [$(echo $mani_sorted | tr '\n' ' ')] union: [$(echo $union_sorted | tr '\n' ' ')]"
    fi
  done

  # --- agent-bound docs: two-level existence (unit or unit-internal path) ---
  while IFS= read -r a; do
    [ -z "$a" ] && continue
    while IFS= read -r bind; do
      [ -z "$bind" ] && continue
      unit=${bind%%/*}
      declared="no"
      jq -e --arg u "$unit" '(.docs // []) + (.shared.docs // []) | index($u) != null' "$m" >/dev/null \
        && declared="yes"
      [ "$declared" = "yes" ] || fail "agent $a binds undeclared doc unit: $bind"
      if [ "$bind" != "$unit" ]; then
        if [ -e "$d/docs/$bind" ]; then :; elif [ -e "$SHARED_DIR/docs/$bind" ]; then :; else
          fail "agent $a binds non-existent doc path: $bind"
        fi
      fi
    done < <(fm_list "$d/agents/$a.md" docs)
  done < <(jq -r '.agents[]? // empty' "$m")
done

finish
