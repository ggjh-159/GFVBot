#!/usr/bin/env bash
# uninstall.sh — reverse GFVBot installs per their records (backend of
# `gfvbot uninstall`).
#
# Usage:
#   uninstall.sh <plugin>... [--target <dir>] [--dry-run]
#
# Rules:
#   - landed files are deleted per the plugin's record
#   - shared units (skills/docs/templates) are reference-counted across the
#     remaining records; the last referencing plugin takes the content with it
#   - entry files (CLAUDE.md / AGENTS.md) are never deleted by the file list;
#     only their anchor section is removed — and the file itself only when it
#     ends up empty
#   - when the last record is gone the whole territory is reclaimed:
#     index files, anchors, empty layout dirs, and .gfvbot/ itself

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
. "$ROOT/installer/lib/common.sh"

DRY_RUN=""
TARGET=""
PLUGINS=()

usage() {
  if [ "$T_LANG" = zh ]; then
    cat <<'EOF'
uninstall.sh — 按安装记录逆操作 GFVBot 安装（gfvbot uninstall 的后端）

用法:
  uninstall.sh <插件名>... [--tool <claude|opencode>] [--target <dir>] [--dry-run]
  不带 --tool 时删除该插件在所有 AI Agent 下的安装；
  插件装在多个 AI Agent 下且终端可交互时会弹出勾选列表
EOF
  else
    cat <<'EOF'
uninstall.sh — reverse GFVBot installs per their records (backend of
`gfvbot uninstall`).

Usage:
  uninstall.sh <plugin>... [--tool <claude|opencode>] [--target <dir>] [--dry-run]
  Without --tool every install of the plugin (all tools) is removed; with the
  plugin spanning several tools an interactive tick-list asks which to remove
EOF
  fi
  exit 0
}

TOOL_FILTER=""
while [ $# -gt 0 ]; do
  case "$1" in
    --tool)    [ $# -ge 2 ] || die "$(t err_needs_value --tool)"; TOOL_FILTER="$2"; shift 2 ;;
    --target)  [ $# -ge 2 ] || die "$(t err_needs_value --target)"; TARGET="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage ;;
    --) shift; while [ $# -gt 0 ]; do PLUGINS+=("$1"); shift; done; break ;;
    *) PLUGINS+=("$1"); shift ;;
  esac
done

[ "${#PLUGINS[@]}" -gt 0 ] || die "$(t err_no_plugin_given)"
TARGET="${TARGET:-$PWD}"
RECORDS_DIR="$TARGET/.gfvbot/records"
[ -d "$RECORDS_DIR" ] || die "$(t err_no_records "$TARGET")"

rm_path() {  # <path> <label>
  if [ -e "$1" ] || [ -L "$1" ]; then
    if [ -n "$DRY_RUN" ]; then
      echo "  $(t dry_remove "$1")"
    else
      rm -rf "$1"
      ok "$(t removed "$2" "$1")"
    fi
  fi
}



# ---------------------------------------------------------------------------
# collect the work set (record files) and the surviving records
# ---------------------------------------------------------------------------
UNINSTALL=()
for p in "${PLUGINS[@]}"; do
  matched=0
  for rec in "$RECORDS_DIR"/*.json; do
    [ -f "$rec" ] || continue
    [ "$(jq -r '.plugin' "$rec")" = "$p" ] || continue
    [ -z "$TOOL_FILTER" ] || [ "$(jq -r '.tool' "$rec")" = "$TOOL_FILTER" ] || continue
    UNINSTALL+=("$rec")
    matched=1
  done
  [ "$matched" = 1 ] || warn "$(t warn_no_record "$p" "$TARGET")"
done
[ "${#UNINSTALL[@]}" -gt 0 ] || die "$(t err_nothing)"

# ---------------------------------------------------------------------------
# interactive selection — when a plugin spans several tools and no --tool
# filter narrows it down, a tick-list asks which installs to remove.
# Only for a real terminal; pipes/scripts keep the remove-all behavior.
# ---------------------------------------------------------------------------
ui_pick_installs() {  # <item>... ("plugin|tool|record") → PICKED=(), rc 1 = cancelled
  local items=("$@")
  local n=${#items[@]}
  local -a checked=()
  local i p tool w=6
  for ((i = 0; i < n; i++)); do checked[$i]=1; done
  for i in "${items[@]}"; do
    p=${i%%|*}
    [ "${#p}" -gt "$w" ] && w="${#p}"
  done
  local cur=0 key sub
  local saved_tty
  saved_tty=$(stty -g)
  stty raw -echo min 1 time 0    # own the terminal: keys arrive byte-wise
  _pick_fini() { stty "$saved_tty"; printf '\033[?25h'; }
  printf '\033[?25l'            # hide cursor
  t ui_pick_title; echo
  t ui_pick_hint; echo
  echo
  _pick_paint() {
    local i mark ptr rest toolname
    for ((i = 0; i < n; i++)); do
      [ "${checked[$i]}" = 1 ] && mark="✔" || mark=" "
      [ "$i" = "$cur" ] && ptr=">" || ptr=" "
      rest=${items[$i]#*|}
      toolname=${rest%%|*}
      printf '  %s %s %-*s  %s\n' "$ptr" "$mark" "$w" "${items[$i]%%|*}" "$toolname"
    done
  }
  _pick_paint
  while true; do
    # -N (not -n): read the byte verbatim — -n would swallow CR/LF as line
    # delimiters and Enter would never reach the case below
    if ! IFS= read -rsN1 key; then
      _pick_fini                # EOF on stdin — refuse to spin, bail out
      die "$(t msg_uninstall_cancelled)"
    fi
    if [[ "$key" == $'\x1b' ]]; then
      IFS= read -rsN2 sub
      case "$sub" in
        '[A') key=UP ;;
        '[B') key=DOWN ;;
      esac
    fi
    case "$key" in
      j|DOWN) [ "$cur" -lt $((n - 1)) ] && cur=$((cur + 1)) ;;
      k|UP)   [ "$cur" -gt 0 ] && cur=$((cur - 1)) ;;
      ' '|x)  checked[$cur]=$((1 - ${checked[$cur]})) ;;
      $'\r'|$'\n') break ;;
      q|Q)    _pick_fini; return 1 ;;
    esac
    printf '\033[%dA' "$n"
    _pick_paint
  done
  _pick_fini
  PICKED=()
  for ((i = 0; i < n; i++)); do
    [ "${checked[$i]}" = 1 ] && PICKED+=("${items[$i]}")
  done
  return 0   # explicit: the for-loop tail would otherwise leak its status
}

if [ -z "$TOOL_FILTER" ] && [ -t 0 ] && [ -t 1 ]; then
  # items = records of plugins installed under more than one tool
  declare -A _span=()
  for rec in "${UNINSTALL[@]}"; do
    _span[$(jq -r '.plugin' "$rec")]=$((_span[$(jq -r '.plugin' "$rec")] + 1))
  done
  local_items=()
  for rec in "${UNINSTALL[@]}"; do
    p=$(jq -r '.plugin' "$rec")
    [ "${_span[$p]}" -gt 1 ] && local_items+=("$p|$(jq -r '.tool' "$rec")|$rec")
  done
  if [ "${#local_items[@]}" -gt 0 ]; then
    if ui_pick_installs "${local_items[@]}"; then
      declare -A _picked=()
      for it in "${PICKED[@]}"; do _picked["${it##*|}"]=1; done
      _filtered=()
      for rec in "${UNINSTALL[@]}"; do
        if [ "${_span[$(jq -r '.plugin' "$rec")]}" -gt 1 ] && [ -z "${_picked[$rec]:-}" ]; then
          continue
        fi
        _filtered+=("$rec")
      done
      UNINSTALL=("${_filtered[@]}")
    else
      echo
      die "$(t msg_uninstall_cancelled)"
    fi
  fi
elif [ -z "$TOOL_FILTER" ]; then
  # keep remove-all semantics for scripts/pipes, but say so
  declare -A _span=()
  for rec in "${UNINSTALL[@]}"; do
    _span[$(jq -r '.plugin' "$rec")]=$((_span[$(jq -r '.plugin' "$rec")] + 1))
  done
  for p in "${!_span[@]}"; do
    [ "${_span[$p]}" -gt 1 ] && ok "$(t msg_noninteractive_all)"
  done
fi
[ "${#UNINSTALL[@]}" -gt 0 ] || die "$(t err_nothing)"

# tools touched by this run; collected before the records are deleted so the
# reclaim pass below can decide per tool whether its territory is now empty
declare -A AFFECTED=()
for rec in "${UNINSTALL[@]}"; do
  AFFECTED[$(jq -r '.tool' "$rec")]=1
done

declare -A SURVIVING=()
declare -A SURVIVING_TOOLS=()
declare -A SURVIVOR_FILES=()
for rec in "$RECORDS_DIR"/*.json; do
  [ -f "$rec" ] || continue
  skip=0
  for u in "${UNINSTALL[@]}"; do [ "$u" = "$rec" ] && { skip=1; break; }; done
  [ "$skip" = 1 ] && continue
  rp=$(jq -r '.plugin' "$rec")
  SURVIVING["$rp"]=1
  SURVIVING_TOOLS["$(jq -r '.tool' "$rec")"]=1
  # every landing path a surviving record still covers: shared units (any
  # kind, landing per tool layout) and the tool-independent docs/templates
  # paths a dual-tool install of the same plugin lists twice — one check
  # covers both
  while IFS= read -r f; do
    [ -n "$f" ] && SURVIVOR_FILES["$f"]=1
  done < <(jq -r '.files[]' "$rec")
done

# ---------------------------------------------------------------------------
# per-record removal
# ---------------------------------------------------------------------------
for rec in "${UNINSTALL[@]}"; do
  p=$(jq -r '.plugin' "$rec")
  tool=$(jq -r '.tool' "$rec")
  index=$(index_path "$tool" "$TARGET")
  step "$(t step_uninstall "$p" "$tool")"

  # 1. drop this plugin's section from the index
  section_remove "$index" "<!-- gfvbot:plugin:$p -->" "<!-- /gfvbot:plugin:$p -->"

  # 2. delete landed files, skipping index/entry files (anchor-managed) and
  #    paths still covered by a surviving record (shared units, and the
  #    tool-independent docs of a dual-tool install)
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    [ "$f" = "$index" ] && continue
    [ "$f" = "$TARGET/CLAUDE.md" ] && continue
    [ "$f" = "$TARGET/AGENTS.md" ] && continue
    if [ -n "${SURVIVOR_FILES[$f]:-}" ]; then
      ok "$(t msg_file_kept "$f")"
      continue
    fi
    rm_path "$f" "$(t lbl_file)"
  done < <(jq -r '.files[]' "$rec")

  # 3. entry anchor body refresh where it mirrors the index (opencode/codex)
  entry="$TARGET/AGENTS.md"
  if [ "$tool" = "opencode" ] || [ "$tool" = "codex" ]; then
    if [ -f "$entry" ] && section_exists "$entry" "<!-- gfvbot -->" && [ -f "$index" ]; then
      copy=$(mktemp)
      cat "$index" > "$copy"
      section_upsert "$entry" "<!-- gfvbot -->" "<!-- /gfvbot -->" "$copy"
    fi
  fi

  # 4. per-plugin docs dir prune (rmdir is a no-op on non-empty dirs)
  if [ -z "$DRY_RUN" ]; then
    rmdir --ignore-fail-on-non-empty "$TARGET/docs/gfvbot/$p/templates" 2>/dev/null
    rmdir --ignore-fail-on-non-empty "$TARGET/docs/gfvbot/$p" 2>/dev/null
  fi

  rm_path "$rec" "$(t lbl_record)"
done

# ---------------------------------------------------------------------------
# territory reclaim — per tool: the last record of a tool takes the tool's
# layout with it; the last record overall takes docs/ and .gfvbot/ with it
# ---------------------------------------------------------------------------
if [ "${#SURVIVING[@]}" -eq 0 ]; then
  step "$(t step_reclaim)"
fi
for tool in "${!AFFECTED[@]}"; do
  [ -z "${SURVIVING_TOOLS[$tool]:-}" ] || continue
  step "$(t step_reclaim_tool "$tool")"
  index=$(index_path "$tool" "$TARGET")
  case "$tool" in
    claude) entry="$TARGET/CLAUDE.md" ;;
    *)      entry="$TARGET/AGENTS.md" ;;
  esac
  # AGENTS.md is the entry of both opencode and codex: only strip the anchor
  # when no surviving tool still uses the same file
  share_entry=""
  if [ "$entry" = "$TARGET/AGENTS.md" ]; then
    for st in opencode codex; do
      [ "$st" = "$tool" ] && continue
      [ -n "${SURVIVING_TOOLS[$st]:-}" ] && share_entry=1
    done
  fi
  if [ -z "$share_entry" ] && [ -f "$entry" ]; then
    section_remove "$entry" "<!-- gfvbot -->" "<!-- /gfvbot -->"
    # file created by the installer and now empty → take it with us
    if [ -z "$(tr -d '[:space:]' < "$entry")" ]; then
      rm_path "$entry" "$(t lbl_entry)"
    fi
  fi
  rm_path "$index" "$(t lbl_index)"
  case "$tool" in
    claude)   reclaim_dirs=(.claude/gfvbot .claude/skills .claude/agents .claude) ;;
    opencode) reclaim_dirs=(.opencode/gfvbot .opencode/skills .opencode/agents .opencode) ;;
    codex)    reclaim_dirs=(.codex/gfvbot .codex/prompts .codex) ;;
    dsh)      reclaim_dirs=(.agents/gfvbot .agents/skills .agents) ;;
  esac
  for d in "${reclaim_dirs[@]}"; do
    [ -n "$DRY_RUN" ] || rmdir --ignore-fail-on-non-empty "$TARGET/$d" 2>/dev/null
  done
  ok "$(t msg_tool_reclaimed "$tool")"
done
if [ "${#SURVIVING[@]}" -eq 0 ]; then
  for d in \
    "$TARGET/docs/gfvbot/shared/templates" "$TARGET/docs/gfvbot/shared" "$TARGET/docs/gfvbot" "$TARGET/docs"; do
    [ -n "$DRY_RUN" ] || rmdir --ignore-fail-on-non-empty "$d" 2>/dev/null
  done
  # user-set language config is user content, not installer territory: keep it
  if [ -f "$TARGET/.gfvbot/config" ]; then
    [ -n "$DRY_RUN" ] || rm -rf "$TARGET/.gfvbot/records"
    ok "$(t msg_config_kept "$TARGET/.gfvbot/config")"
  else
    rm_path "$TARGET/.gfvbot" "$(t lbl_records_root)"
  fi
  ok "$(t msg_reclaimed)"
else
  ok "$(t msg_remaining "${!SURVIVING[*]}")"
fi
