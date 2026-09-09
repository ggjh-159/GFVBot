#!/usr/bin/env bash
# install.sh — GFVBot install engine (backend of `gfvbot install`).
#
# Usage:
#   install.sh [--plugin <name>]... [--all] [--tool <claude|opencode>]
#              [--target <dir>] [--dry-run] [--link]
#   install.sh <plugin> [tool]      # positional shortcut (thin-entry style)
#   install.sh                      # no args → interactive
#
# Engine behavior: consume plugin.json manifests, verify declared units exist,
# delegate landing layout to adapters/<tool>.sh, write per-plugin install
# records under <target>/.gfvbot/records/, run a post-install health check.

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
. "$ROOT/installer/lib/common.sh"

PLUGINS_DIR="$ROOT/plugins"
SHARED_DIR="$ROOT/shared"
TOOLS="claude opencode"

DRY_RUN=""
LINK_MODE=""
TOOL=""
TARGET=""
PLUGINS=()
ALL=""

usage() {
  if [ "$T_LANG" = zh ]; then
    cat <<'EOF'
install.sh — GFVBot安装引擎（gfvbot install的后端）

用法:
  install.sh [--plugin <name>]... [--all] [--tool <claude|opencode>]
             [--target <dir>] [--dry-run] [--link]
  install.sh <插件名> [AI Agent]  # 位置参数简写（薄入口风格）
  install.sh                      # 无参数 → 交互式选择
EOF
  else
    cat <<'EOF'
install.sh — GFVBot install engine (backend of `gfvbot install`)

Usage:
  install.sh [--plugin <name>]... [--all] [--tool <claude|opencode>]
             [--target <dir>] [--dry-run] [--link]
  install.sh <plugin> [tool]      # positional shortcut (thin-entry style)
  install.sh                      # no args → interactive
EOF
  fi
  exit 0
}


# ---------------------------------------------------------------------------
# argument parsing
# ---------------------------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --plugin)  [ $# -ge 2 ] || die "$(t err_needs_value --plugin)"; PLUGINS+=("$2"); shift 2 ;;
    --all)     ALL=1; shift ;;
    --tool)    [ $# -ge 2 ] || die "$(t err_needs_value --tool)"; TOOL="$2"; shift 2 ;;
    --target)  [ $# -ge 2 ] || die "$(t err_needs_value --target)"; TARGET="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --link)    LINK_MODE=1; shift ;;
    -h|--help) usage ;;
    *)
      if [ -z "$TOOL" ] && [[ " $TOOLS " == *" $1 "* ]]; then
        TOOL="$1"; shift
      elif [ -d "$PLUGINS_DIR/$1" ]; then
        PLUGINS+=("$1"); shift
      else
        die "$(t err_unknown_arg "$1")"
      fi
      ;;
  esac
done

require_core_tools
[ -d "$SHARED_DIR" ] || die "$(t err_shared_missing "$ROOT")"

# interactive fallback: no plugin selected → choose; no tool → choose
if [ -z "$ALL" ] && [ "${#PLUGINS[@]}" -eq 0 ]; then
  t ui_avail_plugins; echo
  local_plugins=$(ls "$PLUGINS_DIR")
  select p in $local_plugins; do
    [ -n "$p" ] && { PLUGINS+=("$p"); break; }
  done
fi
if [ -z "$TOOL" ]; then
  t ui_select_tool; echo
  select t in $TOOLS; do
    [ -n "$t" ] && { TOOL="$t"; break; }
  done
fi
[[ " $TOOLS " == *" $TOOL "* ]] || die "$(t err_bad_tool "$TOOL" "$TOOLS")"

TARGET="${TARGET:-$PWD}"
[ -d "$TARGET" ] || die "$(t err_target_missing "$TARGET")"

if [ -n "$ALL" ]; then
  PLUGINS=()
  while IFS= read -r d; do PLUGINS+=("$d"); done < <(ls "$PLUGINS_DIR")
fi
[ "${#PLUGINS[@]}" -gt 0 ] || die "$(t err_no_plugin)"

ADAPTER="$ROOT/installer/adapters/$TOOL.sh"
[ -f "$ADAPTER" ] || die "$(t err_adapter "$ADAPTER")"
# shellcheck source=adapters/claude.sh
. "$ADAPTER"

# ---------------------------------------------------------------------------
# manifest validation — every declared unit must exist before anything lands
# ---------------------------------------------------------------------------
check_unit() {  # <path> <label>
  [ -e "$1" ] || die "$(t err_unit_missing "$PLUGIN_SEL" "$2" "$1")"
}

validate_manifest() {
  local p=$1
  local m="$PLUGINS_DIR/$p/plugin.json"
  [ -f "$m" ] || die "$(t err_manifest "$m")"
  [ "$(jq -r '.name' "$m")" = "$p" ] || die "$(t err_name_mismatch "$p")"
  [ "$(jq -r '.workflow' "$m")" = "workflow.md" ] || die "$(t err_workflow_field "$p")"
  [ -f "$PLUGINS_DIR/$p/workflow.md" ] || die "$(t err_workflow_missing "$p")"
  local u kind
  for u in $(jq -r '.agents[]? // empty' "$m"); do
    check_unit "$PLUGINS_DIR/$p/agents/$u.md" "agent"
  done
  for u in $(jq -r '.skills[]? // empty' "$m"); do
    check_unit "$PLUGINS_DIR/$p/skills/$u" "skill"
  done
  for u in $(jq -r '.docs[]? // empty' "$m"); do
    check_unit "$PLUGINS_DIR/$p/docs/$u" "doc"
  done
  for u in $(jq -r '.templates[]? // empty' "$m"); do
    check_unit "$PLUGINS_DIR/$p/templates/$u" "template"
  done
  for kind in skills docs templates; do
    for u in $(jq -r ".shared.$kind[]? // empty" "$m"); do
      check_unit "$SHARED_DIR/$kind/$u" "shared $kind"
    done
  done
}

# ---------------------------------------------------------------------------
# source fingerprint — plugin content (minus source-state files and evals)
# plus declared shared units; any content change flips the record to UPDATE
# ---------------------------------------------------------------------------
fingerprint() {
  local p=$1
  local m="$PLUGINS_DIR/$p/plugin.json"
  local kind u
  {
    find "$PLUGINS_DIR/$p" -type f \
      ! -name install.sh ! -name quickstart.md ! -name quickstart.zh.md \
      ! -name prompt.md ! -name prompt.zh.md ! -path '*/evals/*' \
      | LC_ALL=C sort | xargs -r sha256sum
    for kind in skills docs templates; do
      while IFS= read -r u; do
        [ -n "$u" ] || continue
        find "$SHARED_DIR/$kind/$u" -type f 2>/dev/null \
          | LC_ALL=C sort | xargs -r sha256sum
      done < <(jq -r ".shared.$kind[]? // empty" "$m")
    done
  } | sha256sum | cut -d' ' -f1
}

# ---------------------------------------------------------------------------
# install one plugin: three-state decision → adapter → stale cleanup →
# record → health check
# ---------------------------------------------------------------------------
install_one() {
  local p=$1
  local m="$PLUGINS_DIR/$p/plugin.json"
  local rec; rec=$(record_path "$TARGET" "$p" "$TOOL")
  local fp; fp=$(fingerprint "$p")
  local cur_link=false; [ -n "$LINK_MODE" ] && cur_link=true
  local state=NEW old_entry=false
  local old_files=()

  # records are keyed by plugin+tool: installing the same plugin under
  # another tool coexists; each record's lifecycle is independent
  if [ -f "$rec" ]; then
    old_entry=$(jq -r '.entry_created' "$rec")
    if [ "$(jq -r '.fingerprint' "$rec")" = "$fp" ] \
       && [ "$(jq -r '.link' "$rec")" = "$cur_link" ]; then
      ok "$(t msg_skip "$p")"
      return 0
    fi
    state=UPDATE
    mapfile -t old_files < <(jq -r '.files[]' "$rec")
  fi

  step "$(t step_install "$p" "$state" "$TOOL" "$TARGET")${LINK_MODE:+$(t link_mode_suffix)}"
  ENTRY_CREATED=$old_entry
  INSTALLED_FILES=()
  adapter_install "$p" "$m" "$TARGET"

  # stale cleanup: files landed by the previous install that this one no longer covers
  if [ "$state" = "UPDATE" ]; then
    local f g found
    for f in "${old_files[@]:-}"; do
      [ -n "$f" ] || continue
      found=0
      for g in "${INSTALLED_FILES[@]:-}"; do [ "$g" = "$f" ] && { found=1; break; }; done
      [ "$found" = 0 ] || continue
      if [ -e "$f" ] || [ -L "$f" ]; then
        if [ -n "$DRY_RUN" ]; then
          echo "  $(t dry_remove_stale "$f")"
        else
          rm -rf "$f"
          ok "$(t msg_stale "$f")"
        fi
      fi
    done
  fi

  FINGERPRINT="$fp"
  record_write "$TARGET" "$p" "$TOOL" "$cur_link"

  if [ -z "$DRY_RUN" ]; then
    local f hc=0
    for f in "${INSTALLED_FILES[@]:-}"; do
      [ -n "$f" ] && { [ -e "$f" ] || { err "$(t err_health_missing "$f")"; hc=1; }; }
    done
    if [ "$hc" = 0 ]; then
      ok "$(t msg_health_ok "$p" "${#INSTALLED_FILES[@]}")"
    else
      die "$(t err_health_failed "$p")"
    fi
  fi
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
for PLUGIN_SEL in "${PLUGINS[@]}"; do
  [ -d "$PLUGINS_DIR/$PLUGIN_SEL" ] || die "$(t err_unknown_arg "$PLUGIN_SEL")"
  validate_manifest "$PLUGIN_SEL"
done

for p in "${PLUGINS[@]}"; do
  install_one "$p"
done

step "$(t step_done "${#PLUGINS[@]}" "$TOOL" "$TARGET")"
