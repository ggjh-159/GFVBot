#!/usr/bin/env bash
# check_language.sh — L1: content language policy.
#   AI-facing content (workflow.md, agents/, skills/) must be English-only.
#   Docs and base templates are bilingual: the main file is English-only and
#   Chinese lives in a <base>.zh.md sibling; templates pair through the
#   manifest, docs pair through the filesystem.

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$TESTS_DIR/lib.sh"
ROOT="$(cd "$TESTS_DIR/../.." && pwd)"
PLUGINS_DIR="$ROOT/plugins"
SHARED_DIR="$ROOT/shared"

# CJK detector: byte-range grep, locale-independent (CJK lead bytes are
# E3..EF; Latin typography like the em-dash lives at E2 and stays legal)
has_cjk() { LC_ALL=C grep -q $'[\xe3-\xef]' "$1"; }

check_english_tree() {  # <dir> <what>
  local f
  [ -d "$1" ] || return 0
  while IFS= read -r f; do
    if has_cjk "$f"; then
      fail "CJK in $2: ${f#"$ROOT"/}"
    else
      pass "english-only $2: ${f#"$ROOT"/}"
    fi
  done < <(find "$1" -type f ! -name .gitkeep | LC_ALL=C sort)
}

check_base_templates_english() {  # <templates-dir>
  local f
  [ -d "$1" ] || return 0
  while IFS= read -r f; do
    case "$f" in *.zh.md) continue ;; esac
    if has_cjk "$f"; then
      fail "CJK in base template (Chinese belongs in the .zh.md sibling): ${f#"$ROOT"/}"
    else
      pass "english-only template: ${f#"$ROOT"/}"
    fi
  done < <(find "$1" -type f ! -name .gitkeep | LC_ALL=C sort)
}

check_docs_english() {  # <dir> <what> — main doc files are English-only, the
                        # Chinese lives in a .zh.md sibling, and the pair must
                        # exist on disk
  local f sib
  [ -d "$1" ] || return 0
  while IFS= read -r f; do
    case "$f" in *.zh.md) continue ;; esac
    if has_cjk "$f"; then
      fail "CJK in $2 (Chinese belongs in the .zh.md sibling): ${f#"$ROOT"/}"
    else
      pass "english-only $2: ${f#"$ROOT"/}"
    fi
    sib="${f%.md}.zh.md"
    [ -f "$sib" ] \
      && pass "doc pair file exists: ${sib#"$ROOT"/}" \
      || fail "doc missing .zh.md pair file: ${sib#"$ROOT"/}"
  done < <(find "$1" -type f -name "*.md" ! -name .gitkeep | LC_ALL=C sort)
}

for d in "$PLUGINS_DIR"/*/; do
  p=$(basename "$d")
  echo "plugin: $p"
  m="$d/plugin.json"

  # AI-facing content: English only
  if [ -f "$d/workflow.md" ]; then
    has_cjk "$d/workflow.md" && fail "CJK in workflow.md of $p" || pass "english-only: $p/workflow.md"
  else
    fail "workflow.md missing: $p"
  fi
  check_english_tree "$d/agents" "agents"
  check_english_tree "$d/skills" "skills"
  check_docs_english "$d/docs" "docs"
  check_base_templates_english "$d/templates"

  # bilingual pairing: every declared .md template unit has a <base>.zh.md
  # sibling that exists and is declared as its own unit
  while IFS= read -r u; do
    [ -z "$u" ] && continue
    case "$u" in *.zh.md) continue ;; esac
    case "$u" in
      *.md)
        sib="${u%.md}.zh.md"
        [ -f "$d/templates/$sib" ] \
          && pass "template pair file exists: $p/$sib" \
          || fail "template missing .zh.md pair file: $p/$sib"
        jq -e --arg s "$sib" '(.templates // []) | index($s) != null' "$m" >/dev/null \
          && pass "template pair declared: $p/$sib" \
          || fail "template pair not declared in manifest: $p/$sib" ;;
    esac
  done < <(jq -r '.templates[]? // empty' "$m")
  while IFS= read -r u; do
    [ -z "$u" ] && continue
    case "$u" in *.zh.md) continue ;; esac
    case "$u" in
      *.md)
        sib="${u%.md}.zh.md"
        [ -f "$SHARED_DIR/templates/$sib" ] \
          && pass "shared template pair file exists: $sib" \
          || fail "shared template missing .zh.md pair file: $sib"
        jq -e --arg s "$sib" '(.shared.templates // []) | index($s) != null' "$m" >/dev/null \
          && pass "shared template pair declared: $sib" \
          || fail "shared template pair not declared in manifest: $sib" ;;
    esac
  done < <(jq -r '.shared.templates[]? // empty' "$m")

  # quickstart is human-facing: pair it when present
  if [ -f "$d/quickstart.md" ]; then
    [ -f "$d/quickstart.zh.md" ] \
      && pass "quickstart bilingual pair: $p" \
      || fail "quickstart missing quickstart.zh.md pair: $p"
  fi

  # task prompt is human-facing: pair it when present
  if [ -f "$d/prompt.md" ]; then
    [ -f "$d/prompt.zh.md" ] \
      && pass "prompt bilingual pair: $p" \
      || fail "prompt missing prompt.zh.md pair: $p"
  fi
done

# shared AI-facing content: English only
check_english_tree "$SHARED_DIR/skills" "shared skills"
check_docs_english "$SHARED_DIR/docs" "shared docs"
check_base_templates_english "$SHARED_DIR/templates"

finish
