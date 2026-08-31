#!/usr/bin/env bash
# codex.sh — OpenAI Codex CLI adapter.
#
# Layout:
#   skills        → rewritten to .codex/prompts/<name>.md (one file per skill:
#                   SKILL.md content verbatim; codex has no skills directory)
#   agents        → merged into the index member sections (no per-agent files)
#   workflow      → .codex/gfvbot/index.md (per-plugin sections, with agents)
#   entry file    → AGENTS.md single anchor, body is a full copy of the index
#   docs/templates→ docs/gfvbot/... (uniform, see lib/common.sh)

codex_skill_install() {  # <skill_src_dir> <dst_md>
  local src=$1 dst=$2
  [ -f "$src/SKILL.md" ] || { err "$(t err_no_skill_md "$src")"; return 1; }
  if [ -n "$LINK_MODE" ]; then
    if [ -n "$DRY_RUN" ]; then
      echo "  $(t dry_link "$src/SKILL.md" "$dst")"
    else
      mkdir -p "$(dirname "$dst")"
      rm -rf "$dst"
      ln -sfn "$(realpath "$src/SKILL.md")" "$dst"
    fi
  else
    local tmp; tmp=$(mktemp)
    cat "$src/SKILL.md" > "$tmp"
    idem_install "$tmp" "$dst"
  fi
  INSTALLED_FILES+=("$dst")
}

adapter_install() {
  local p=$1 m=$2 t=$3
  local u

  while IFS= read -r u; do
    [ -n "$u" ] && codex_skill_install "$PLUGINS_DIR/$p/skills/$u" "$t/.codex/prompts/$u.md"
  done < <(jq -r '.skills[]? // empty' "$m")
  while IFS= read -r u; do
    [ -n "$u" ] && codex_skill_install "$SHARED_DIR/skills/$u" "$t/.codex/prompts/$u.md"
  done < <(shared_skills "$m")

  install_docs_templates "$p" "$m" "$t"

  local index="$t/.codex/gfvbot/index.md"
  ensure_index "$index"
  local sec; sec=$(mktemp)
  gen_index_section "$p" "$PLUGINS_DIR/$p" with_agents "$sec"
  section_upsert "$index" "<!-- gfvbot:plugin:$p -->" "<!-- /gfvbot:plugin:$p -->" "$sec"
  INSTALLED_FILES+=("$index")

  local entry="$t/AGENTS.md"
  [ -f "$entry" ] || ENTRY_CREATED=true
  local anchor; anchor=$(mktemp)
  [ -z "$DRY_RUN" ] && cat "$index" > "$anchor"
  section_upsert "$entry" "<!-- gfvbot -->" "<!-- /gfvbot -->" "$anchor"
  INSTALLED_FILES+=("$entry")
}
