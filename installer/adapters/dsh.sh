#!/usr/bin/env bash
# dsh.sh — DeepSeek Harness (dsh) adapter.
#
# Layout:
#   skills        → .agents/skills/<name>/   (AGENTS.md open-standard path,
#                   auto-discovered by dsh, no rewriting needed)
#   agents        → merged into the index member sections
#   workflow      → .agents/gfvbot/index.md (per-plugin sections, with agents)
#   entry file    → none. Zero intrusion: dsh is in developer preview and its
#                   config shape is not stable, so nothing is written to user
#                   config; instead the user is told to point
#                   instructionFileCandidates at the index.
#   docs/templates→ docs/gfvbot/... (uniform, see lib/common.sh)

adapter_install() {
  local p=$1 m=$2 t=$3
  local u

  while IFS= read -r u; do
    [ -n "$u" ] && idem_install "$PLUGINS_DIR/$p/skills/$u" "$t/.agents/skills/$u"
  done < <(jq -r '.skills[]? // empty' "$m")
  while IFS= read -r u; do
    [ -n "$u" ] && idem_install "$SHARED_DIR/skills/$u" "$t/.agents/skills/$u"
  done < <(shared_skills "$m")

  install_docs_templates "$p" "$m" "$t"

  local index="$t/.agents/gfvbot/index.md"
  ensure_index "$index"
  local sec; sec=$(mktemp)
  gen_index_section "$p" "$PLUGINS_DIR/$p" with_agents "$sec"
  section_upsert "$index" "<!-- gfvbot:plugin:$p -->" "<!-- /gfvbot:plugin:$p -->" "$sec"
  INSTALLED_FILES+=("$index")

  # zero intrusion on entry files: entry_created stays false, nothing removed
  # from user files on uninstall. Print the one-time wiring hint instead.
  if [ -z "$DRY_RUN" ]; then
    warn "$(t dsh_hint "$t/.agents/gfvbot/index.md")"
  fi
}
