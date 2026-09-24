#!/usr/bin/env bash
# opencode.sh — OpenCode adapter.
#
# Layout:
#   skills        → .opencode/skills/<name>/
#   agents        → .opencode/agents/<name>.md
#   workflow      → .opencode/gfvbot/index.md (per-plugin sections)
#   entry file    → AGENTS.md single anchor, body is a full copy of the index
#                   (AGENTS.md has no @import mechanism, so the index content
#                   is mirrored into the anchor body on every install)
#   docs/templates→ docs/gfvbot/... (uniform, see lib/common.sh)

adapter_install() {
  local p=$1 m=$2 t=$3
  local u

  while IFS= read -r u; do
    [ -n "$u" ] && idem_install "$PLUGINS_DIR/$p/$CONTENT_LANG/skills/$u" "$t/.opencode/skills/$u"
  done < <(jq -r '.skills[]? // empty' "$m")
  while IFS= read -r u; do
    [ -n "$u" ] && idem_install "$SHARED_DIR/$CONTENT_LANG/skills/$u" "$t/.opencode/skills/$u"
  done < <(shared_skills "$m")

  while IFS= read -r u; do
    [ -n "$u" ] && idem_install "$PLUGINS_DIR/$p/$CONTENT_LANG/agents/$u.md" "$t/.opencode/agents/$u.md"
  done < <(jq -r '.agents[]? // empty' "$m")

  install_docs_templates "$p" "$m" "$t"

  local index="$t/.opencode/gfvbot/index.md"
  ensure_index "$index"
  local sec; sec=$(mktemp)
  gen_index_section "$p" "$PLUGINS_DIR/$p" workflow_only "$sec"
  section_upsert "$index" "<!-- gfvbot:plugin:$p -->" "<!-- /gfvbot:plugin:$p -->" "$sec"
  INSTALLED_FILES+=("$index")

  local entry="$t/AGENTS.md"
  [ -f "$entry" ] || ENTRY_CREATED=true
  local anchor; anchor=$(mktemp)
  [ -z "$DRY_RUN" ] && cat "$index" > "$anchor"
  section_upsert "$entry" "<!-- gfvbot -->" "<!-- /gfvbot -->" "$anchor"
  INSTALLED_FILES+=("$entry")
}
