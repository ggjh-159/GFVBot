#!/usr/bin/env bash
# check_manifest.sh — L1: plugin.json validity, neutral unit names,
# declared-unit existence under BOTH language trees, frontmatter shape,
# naming, and manifest ↔ agent-binding union consistency.
#
# Units are declared by neutral name (architecture.md, not en/architecture.md):
# the en/ zh/ source trees carry the pairing, and the installer picks one
# language at install time.

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
  for side in en zh; do
    [ -f "$d/$side/workflow.md" ] || fail "workflow.md missing: $side/workflow.md"
  done
  is_kebab "$p" && pass "plugin name kebab-case" || fail "plugin name not kebab-case: $p"

  # unit names are neutral: the en/ zh/ trees pair content, manifests must
  # not carry a language segment
  while IFS= read -r u; do
    [ -z "$u" ] && continue
    case "$u" in
      en/*|zh/*) fail "manifest entry must be neutral (no en/ zh/ prefix): $u" ;;
    esac
  done < <(jq -r '[.agents[]?, .skills[]?, .docs[]?, .templates[]?,
                  .shared.skills[]?, .shared.docs[]?, .shared.templates[]?] | .[]' "$m")

  # workflow.md frontmatter keys (values may still be empty placeholders)
  [ -n "$(fm_scalar "$d/en/workflow.md" scheduler)" ] || grep -q '^scheduler:' "$d/en/workflow.md" \
    && pass "workflow frontmatter declares scheduler" \
    || fail "workflow frontmatter missing scheduler key"
  grep -q '^stages:' "$d/en/workflow.md" || fail "workflow frontmatter missing stages key"

  sp=$(scene_prefix "$p")

  # --- plugin-owned units: existence under both trees, naming, scene prefix ---
  while IFS= read -r u; do
    [ -z "$u" ] && continue
    for side in en zh; do
      [ -f "$d/$side/agents/$u.md" ] || fail "declared agent missing: $side/agents/$u.md"
      grep -q '^name:' "$d/$side/agents/$u.md" || fail "agent frontmatter missing name key: $side/$u"
      grep -q '^description:' "$d/$side/agents/$u.md" || fail "agent frontmatter missing description key: $side/$u"
      grep -q '^skills:' "$d/$side/agents/$u.md" || fail "agent frontmatter missing skills key: $side/$u"
      grep -q '^docs:' "$d/$side/agents/$u.md" || fail "agent frontmatter missing docs key: $side/$u"
    done
    case "$u" in "$sp"-*) pass "agent scene-prefixed: $u" ;; *) fail "agent not scene-prefixed ($sp-): $u" ;; esac
  done < <(jq -r '.agents[]? // empty' "$m")

  while IFS= read -r u; do
    [ -z "$u" ] && continue
    for side in en zh; do
      [ -d "$d/$side/skills/$u" ] || fail "declared skill missing: $side/skills/$u"
    done
    case "$u" in "$sp"-*) : ;; *) fail "skill not scene-prefixed ($sp-): $u" ;; esac
  done < <(jq -r '.skills[]? // empty' "$m")

  while IFS= read -r u; do
    [ -z "$u" ] && continue
    for side in en zh; do
      [ -e "$d/$side/docs/$u" ] || fail "declared doc missing: $side/docs/$u"
    done
  done < <(jq -r '.docs[]? // empty' "$m")

  while IFS= read -r u; do
    [ -z "$u" ] && continue
    for side in en zh; do
      [ -e "$d/$side/templates/$u" ] || fail "declared template missing: $side/templates/$u"
    done
  done < <(jq -r '.templates[]? // empty' "$m")

  # --- shared declarations: existence under both trees ---
  for kind in skills docs templates; do
    while IFS= read -r u; do
      [ -z "$u" ] && continue
      for side in en zh; do
        [ -e "$SHARED_DIR/$side/$kind/$u" ] || fail "declared shared $kind missing: shared/$side/$kind/$u"
      done
    done < <(jq -r ".shared.$kind[]? // empty" "$m")
  done

  # --- manifest ↔ agent-binding union consistency ---
  # agents may bind owned or shared units by neutral name; the union of what
  # agents bind must equal what the manifest declares (own + shared), in both
  # skills and docs. Bindings are read from the en/ agent files; the zh/
  # twins must carry identical bindings (checked in check_language.sh).
  # Skipped while a plugin declares no agents yet (population phase): there is
  # nothing to compare against, and the check re-engages once agents land.
  agent_count=$(jq -r '.agents[]? // empty' "$m" | wc -l)
  if [ "$agent_count" -eq 0 ]; then
    echo "    --: agent-binding union check skipped (no agents declared yet)"
  fi
  for kind in skills docs; do
    [ "$agent_count" -eq 0 ] && continue
    mani=$(jq -r "[(.${kind}[]?), (.shared.${kind}[]?)] | unique | .[]" "$m")
    agent_union=""
    while IFS= read -r a; do
      [ -z "$a" ] && continue
      agent_union="$agent_union$(fm_list "$d/en/agents/$a.md" "$kind")"$'\n'
    done < <(jq -r '.agents[]? // empty' "$m")
    mani_sorted=$(printf '%s' "$mani" | LC_ALL=C sort -u)
    union_sorted=$(printf '%s' "$agent_union" | LC_ALL=C sort -u | sed '/^$/d')
    if [ "$mani_sorted" = "$union_sorted" ]; then
      pass "manifest $kind == union of agent bindings"
    else
      fail "$kind mismatch — manifest: [$(echo $mani_sorted | tr '\n' ' ')] union: [$(echo $union_sorted | tr '\n' ' ')]"
    fi
  done

  # --- agent-bound docs: unit or unit-internal path (units may themselves
  #     contain slashes, e.g. internals/plan.md, so match the longest declared
  #     prefix rather than the first path segment) ---
  while IFS= read -r a; do
    [ -z "$a" ] && continue
    while IFS= read -r bind; do
      [ -z "$bind" ] && continue
      declared="no"
      while IFS= read -r u2; do
        [ -z "$u2" ] && continue
        case "$bind" in
          "$u2"|"$u2"/*) declared="yes"; break ;;
        esac
      done < <(jq -r '(.docs // []) + (.shared.docs // []) | .[]' "$m")
      [ "$declared" = "yes" ] || fail "agent $a binds undeclared doc unit: $bind"
      if [ -e "$d/en/docs/$bind" ] && [ -e "$d/zh/docs/$bind" ]; then :; elif [ -e "$SHARED_DIR/en/docs/$bind" ] && [ -e "$SHARED_DIR/zh/docs/$bind" ]; then :; else
        fail "agent $a binds non-existent doc path (either tree): $bind"
      fi
    done < <(fm_list "$d/en/agents/$a.md" docs)
  done < <(jq -r '.agents[]? // empty' "$m")
done

finish
