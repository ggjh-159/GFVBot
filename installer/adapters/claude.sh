#!/usr/bin/env bash
# claude.sh — Claude Code adapter.
#
# Layout:
#   skills        → .claude/skills/<name>/
#   agents        → .claude/agents/<name>.md
#   workflow      → .claude/gfvbot/index.md (per-plugin sections)
#   entry file    → CLAUDE.md single anchor, body is one @import line
#   docs/templates→ docs/gfvbot/... (uniform, see lib/common.sh)

adapter_install() {
  local p=$1 m=$2 t=$3
  local u

  while IFS= read -r u; do
    [ -n "$u" ] && idem_install "$PLUGINS_DIR/$p/skills/$u" "$t/.claude/skills/$u"
  done < <(jq -r '.skills[]? // empty' "$m")
  while IFS= read -r u; do
    [ -n "$u" ] && idem_install "$SHARED_DIR/skills/$u" "$t/.claude/skills/$u"
  done < <(shared_skills "$m")

  while IFS= read -r u; do
    [ -n "$u" ] && idem_install "$PLUGINS_DIR/$p/agents/$u.md" "$t/.claude/agents/$u.md"
  done < <(jq -r '.agents[]? // empty' "$m")

  install_docs_templates "$p" "$m" "$t"

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
