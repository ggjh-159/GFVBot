#!/usr/bin/env bash
# check_dependencies.sh — L1 dependency rules:
#   1. plugins are mutually independent — no manifest references another plugin
#   2. plugin-owned skill & agent names are globally unique across plugins
#   3. shared/ never references plugin content
#   4. every shared unit is referenced by >= 2 plugins

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$TESTS_DIR/lib.sh"
ROOT="$(cd "$TESTS_DIR/../.." && pwd)"
PLUGINS_DIR="$ROOT/plugins"
SHARED_DIR="$ROOT/shared"

plugins=()
for d in "$PLUGINS_DIR"/*/; do plugins+=("$(basename "$d")"); done

# 1. zero cross-plugin references
for p in "${plugins[@]}"; do
  m="$PLUGINS_DIR/$p/plugin.json"
  [ -f "$m" ] || continue
  for other in $(jq -r '[.agents[]?, .skills[]?, .docs[]?, .templates[]?,
                         .shared.skills[]?, .shared.docs[]?, .shared.templates[]?] | .[]' "$m"); do
    for q in "${plugins[@]}"; do
      if [ "$q" != "$p" ] && [ "$other" = "$q" ]; then
        fail "$p manifest references other plugin name: $q"
      fi
    done
    case "$other" in
      ../*|*/../*) fail "$p manifest escapes its unit scope: $other" ;;
    esac
  done
done
pass "cross-plugin reference scan done"

# 2. global uniqueness of plugin-owned skill and agent names
for kind in skills agents; do
  names=""
  for p in "${plugins[@]}"; do
    m="$PLUGINS_DIR/$p/plugin.json"
    [ -f "$m" ] || continue
    field=$kind; [ "$kind" = "agents" ] && field="agents"
    names="$names$(jq -r ".$field[]? // empty" "$m")"$'\n'
  done
  dupes=$(printf '%s' "$names" | sed '/^$/d' | LC_ALL=C sort | uniq -d)
  if [ -z "$dupes" ]; then
    pass "$kind names globally unique across plugins"
  else
    fail "duplicate $kind names across plugins: $(echo $dupes)"
  fi
done

# 3. shared/ must not reference plugin content
if grep -rn --include='*.md' --include='*.json' --include='SKILL.md' 'plugins/' "$SHARED_DIR" 2>/dev/null | grep -v '\.gitkeep' | grep -q .; then
  fail "shared/ references plugins/ content"
else
  pass "shared/ free of plugin references"
fi

# 4. shared units must be referenced by >= 2 plugins
for kind in skills docs templates; do
  for unit_dir in "$SHARED_DIR/$kind"/*/; do
    [ -d "$unit_dir" ] || continue
    u=$(basename "$unit_dir")
    refs=0
    for p in "${plugins[@]}"; do
      m="$PLUGINS_DIR/$p/plugin.json"
      [ -f "$m" ] || continue
      jq -e --arg u "$u" '(.shared.docs // []) + (.shared.skills // []) + (.shared.templates // []) | index($u) != null' "$m" >/dev/null \
        && refs=$((refs + 1))
    done
    if [ "$refs" -lt 2 ]; then
      fail "shared $kind '$u' referenced by $refs plugins (< 2) — single-scene content belongs in the plugin"
    else
      pass "shared $kind '$u' referenced by $refs plugins"
    fi
  done
done

finish
