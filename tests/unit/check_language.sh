#!/usr/bin/env bash
# check_language.sh — L1: content language policy.
#   AI-facing content (workflow.md, agents/, skills/) must be English-only.
#   Docs and templates are bilingual through mirrored en/ and zh/ directory
#   trees: every markdown unit under en/ has its zh/ counterpart (on disk and
#   in the manifest), the en/ side is English-only, and nothing lives directly
#   under docs/ or templates/ outside the two language trees. Single files
#   outside those trees (quickstart, prompt) keep the <base>.zh.md suffix
#   pair, like the repo README.

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

check_bilingual_tree() {  # <dir> <what> — a docs/ or templates/ directory
  local f rel base="$1" what="$2"
  [ -d "$base" ] || return 0

  # nothing outside the two language trees, and no suffix-pair leftovers
  while IFS= read -r f; do
    case "$f" in
      "$base/en/"*|"$base/zh/"*) : ;;
      *) fail "$what outside en/ zh/ trees: ${f#"$ROOT"/}" ;;
    esac
  done < <(find "$base" -type f -name '*.md' ! -name .gitkeep | LC_ALL=C sort)
  while IFS= read -r f; do
    fail "suffix pair no longer used in $what (zh/ tree instead): ${f#"$ROOT"/}"
  done < <(find "$base" -type f -name '*.zh.md' | LC_ALL=C sort)

  # en side: English-only, and every unit mirrored on disk under zh/
  [ -d "$base/en" ] || return 0
  while IFS= read -r f; do
    rel="${f#"$base/en/"}"
    if has_cjk "$f"; then
      fail "CJK in $what en tree: ${f#"$ROOT"/}"
    else
      pass "english-only $what en: ${f#"$ROOT"/}"
    fi
    [ -f "$base/zh/$rel" ] \
      && pass "$what zh mirror exists: $rel" \
      || fail "$what missing zh mirror: ${f#"$ROOT"/}"
  done < <(find "$base/en" -type f -name '*.md' ! -name .gitkeep | LC_ALL=C sort)

  # zh side: no orphans
  while IFS= read -r f; do
    rel="${f#"$base/zh/"}"
    [ -f "$base/en/$rel" ] \
      || fail "$what zh unit without en mirror: ${f#"$ROOT"/}"
  done < <(find "$base/zh" -type f -name '*.md' ! -name .gitkeep | LC_ALL=C sort)
}

check_manifest_lang_mirror() {  # <manifest> <jq-field> <src-dir> <what>
  local m="$1" field="$2" dir="$3" what="$4" u twin
  while IFS= read -r u; do
    [ -z "$u" ] && continue
    case "$u" in
      en/*) twin="zh/${u#en/}" ;;
      zh/*) twin="en/${u#zh/}" ;;
      *) fail "$what unit not under en/ or zh/: $u" ; continue ;;
    esac
    [ -e "$dir/$twin" ] || fail "$what twin missing on disk: $twin"
    jq -e --arg t "$twin" "($field // []) | index(\$t) != null" "$m" >/dev/null \
      && pass "$what twin declared: $twin" \
      || fail "$what twin not declared in manifest: $twin"
  done < <(jq -r "($field // []) | .[]" "$m")
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

  # bilingual trees: mirrored en/ zh/ directories, on disk and in the manifest
  check_bilingual_tree "$d/docs" "docs"
  check_bilingual_tree "$d/templates" "templates"
  check_manifest_lang_mirror "$m" .docs "$d/docs" "plugin docs"
  check_manifest_lang_mirror "$m" .templates "$d/templates" "plugin templates"
  check_manifest_lang_mirror "$m" .shared.docs "$SHARED_DIR/docs" "shared docs"
  check_manifest_lang_mirror "$m" .shared.templates "$SHARED_DIR/templates" "shared templates"

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
check_bilingual_tree "$SHARED_DIR/docs" "shared docs"
check_bilingual_tree "$SHARED_DIR/templates" "shared templates"

finish
