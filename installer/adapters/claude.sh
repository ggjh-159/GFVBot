#!/usr/bin/env bash
# claude.sh — Claude Code adapter.
#
# Layout:
#   skills        → .claude/skills/<name>/
#   agents        → .claude/agents/<name>.md
#   workflow      → .claude/gfvbot/index.md (per-plugin sections)
#   entry file    → CLAUDE.md single anchor, body is one @import line
#   docs/templates→ docs/gfvbot/... (uniform, see lib/common.sh)
#   agent-teams   → .claude/settings.json env/teammateMode keys (fill-only)

# Claude Code project settings — enable the experimental agent-teams feature
# so a multi-agent gfvbot install works out of the box, and where tmux is
# installed route teammates into tmux panes for a per-teammate view.
# teammateMode is display-only: without tmux, teammates still run headless
# (observable via the /tasks panel), so the key is written only when tmux
# exists on this machine. Fill-only merge: keys the user already set keep
# their values (warned when they differ from the gfvbot defaults). The file
# is user territory — never added to INSTALLED_FILES; uninstall drops only
# the keys that still hold our values.
ensure_team_settings() {  # <target>
  local tgt=$1 s="$1/.claude/settings.json"
  local have_tmux=0
  command -v tmux >/dev/null 2>&1 && have_tmux=1
  local cur_env="" cur_mode=""
  if [ -f "$s" ] && jq -e . "$s" >/dev/null 2>&1; then
    cur_env=$(jq -r '.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS // empty' "$s")
    cur_mode=$(jq -r '.teammateMode // empty' "$s")
  fi
  if [ -n "$DRY_RUN" ]; then
    echo "  $(t dry_write_settings "$s")"
  else
    mkdir -p "$tgt/.claude"
    [ -f "$s" ] || printf '{}\n' > "$s"
    local merge='.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS //= "1"'
    [ "$have_tmux" = 1 ] && merge="$merge | .teammateMode //= \"tmux\""
    local tmp; tmp=$(mktemp)
    if jq "$merge" "$s" > "$tmp" 2>/dev/null; then
      mv "$tmp" "$s"
      ok "$(t msg_settings_done "$s")"
    else
      rm -f "$tmp"
      warn "$(t warn_settings_invalid "$s")"
    fi
  fi
  [ "$have_tmux" = 0 ] && warn "$(t warn_no_tmux)"
  [ -n "$cur_env" ] && [ "$cur_env" != "1" ] \
    && warn "$(t warn_settings_user "env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" "$cur_env")"
  [ "$have_tmux" = 1 ] && [ -n "$cur_mode" ] && [ "$cur_mode" != "tmux" ] \
    && warn "$(t warn_settings_user "teammateMode" "$cur_mode")"
}

adapter_install() {
  local p=$1 m=$2 t=$3
  local u

  while IFS= read -r u; do
    [ -n "$u" ] && idem_install "$PLUGINS_DIR/$p/$CONTENT_LANG/skills/$u" "$t/.claude/skills/$u"
  done < <(jq -r '.skills[]? // empty' "$m")
  while IFS= read -r u; do
    [ -n "$u" ] && idem_install "$SHARED_DIR/$CONTENT_LANG/skills/$u" "$t/.claude/skills/$u"
  done < <(shared_skills "$m")

  while IFS= read -r u; do
    [ -n "$u" ] && idem_install "$PLUGINS_DIR/$p/$CONTENT_LANG/agents/$u.md" "$t/.claude/agents/$u.md"
  done < <(jq -r '.agents[]? // empty' "$m")

  install_docs_templates "$p" "$m" "$t"

  ensure_team_settings "$t"

  local index="$t/.claude/gfvbot/index.md"
  ensure_index "$index"
  local sec; sec=$(mktemp)
  gen_index_section "$p" "$PLUGINS_DIR/$p" workflow_only "$sec"
  section_upsert "$index" "<!-- gfvbot:plugin:$p -->" "<!-- /gfvbot:plugin:$p -->" "$sec"
  INSTALLED_FILES+=("$index")

  local entry="$t/CLAUDE.md"
  [ -f "$entry" ] || ENTRY_CREATED=true
  local anchor; anchor=$(mktemp)
  printf '@.claude/gfvbot/index.md\n' > "$anchor"
  section_upsert "$entry" "<!-- gfvbot -->" "<!-- /gfvbot -->" "$anchor"
  INSTALLED_FILES+=("$entry")
}
