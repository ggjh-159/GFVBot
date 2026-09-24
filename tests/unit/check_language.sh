#!/usr/bin/env bash
# check_language.sh — L1: content language policy.
#
#   Everything language-dependent lives in the top-level en/ and zh/ subtrees
#   of each plugin (and of shared/): workflow, quickstart, prompt, agents,
#   skills, docs, templates. The two subtrees are structurally mirrored —
#   every file has a twin — the en/ subtree markdown is English-only, and
#   non-markdown payload (bin/, scripts/) is byte-identical across twins
#   (translation touches prose only). The plugin root carries only
#   language-neutral entries: plugin.json, install.sh, evals/, en/, zh/.

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$TESTS_DIR/lib.sh"
ROOT="$(cd "$TESTS_DIR/../.." && pwd)"
PLUGINS_DIR="$ROOT/plugins"
SHARED_DIR="$ROOT/shared"

# CJK detector: byte-range grep, locale-independent (CJK lead bytes are
# E3..EF; Latin typography like the em-dash lives at E2 and stays legal)
has_cjk() { LC_ALL=C grep -q $'[\xe3-\xef]' "$1"; }

# check_lang_subtrees <base> <what> — mirrored en/ zh/ subtrees under <base>
check_lang_subtrees() {
  local base=$1 what=$2
  local f rel
  [ -d "$base/en" ] || { fail "$what has no en/ subtree"; return; }
  [ -d "$base/zh" ] || { fail "$what has no zh/ subtree"; return; }

  # no suffix-pair leftovers: the trees replaced the <base>.zh.md convention
  while IFS= read -r f; do
    fail "suffix pair no longer used in $what (zh/ tree instead): ${f#"$ROOT"/}"
  done < <(find "$base" -type f -name '*.zh.md' | LC_ALL=C sort)

  # en side: markdown English-only; every file mirrored under zh/
  while IFS= read -r f; do
    rel="${f#"$base/en/"}"
    case "$f" in
      *.md)
        if has_cjk "$f"; then
          fail "CJK in $what en subtree: ${f#"$ROOT"/}"
        else
          pass "english-only $what en: ${f#"$ROOT"/}"
        fi ;;
    esac
    [ -f "$base/zh/$rel" ] || fail "$what missing zh twin: ${f#"$ROOT"/}"
  done < <(find "$base/en" -type f | LC_ALL=C sort)

  # zh side: no orphans
  while IFS= read -r f; do
    rel="${f#"$base/zh/"}"
    [ -f "$base/en/$rel" ] || fail "$what zh file without en twin: ${f#"$ROOT"/}"
  done < <(find "$base/zh" -type f | LC_ALL=C sort)

  # non-markdown payload: byte-identical across twins — executable content
  # must not fork between languages
  while IFS= read -r f; do
    rel="${f#"$base/en/"}"
    if [ -f "$base/zh/$rel" ] && cmp -s "$f" "$base/zh/$rel"; then
      pass "$what non-md identical across twins: $rel"
    else
      fail "$what non-md missing or differs in zh twin: $rel"
    fi
  done < <(find "$base/en" -type f ! -name '*.md' | LC_ALL=C sort)
}

for d in "$PLUGINS_DIR"/*/; do
  p=$(basename "$d")
  echo "plugin: $p"
  m="$d/plugin.json"

  # plugin root whitelist: only language-neutral entries beside the trees
  while IFS= read -r e; do
    [ -z "$e" ] && continue
    case "$e" in
      plugin.json|install.sh|en|zh|evals) : ;;
      *) fail "unexpected entry at plugin root: $p/$e" ;;
    esac
  done < <(ls -A "$d")

  check_lang_subtrees "$d" "plugin $p"

  # agent bindings are neutral and identical across the en/ zh/ twins
  while IFS= read -r a; do
    [ -z "$a" ] && continue
    [ -f "$d/en/agents/$a.md" ] && [ -f "$d/zh/agents/$a.md" ] || continue
    for key in skills docs; do
      en_b=$(fm_list "$d/en/agents/$a.md" "$key" | LC_ALL=C sort -u)
      zh_b=$(fm_list "$d/zh/agents/$a.md" "$key" | LC_ALL=C sort -u)
      [ "$en_b" = "$zh_b" ] \
        || fail "agent $a $key bindings differ between en/ zh/ twins: $p"
    done
  done < <(jq -r '.agents[]? // empty' "$m")
done

# shared: mirrored subtrees; the shared root carries only en/ and zh/
while IFS= read -r e; do
  [ -z "$e" ] && continue
  case "$e" in
    en|zh) : ;;
    *) fail "unexpected entry at shared root: shared/$e" ;;
  esac
done < <(ls -A "$SHARED_DIR")
check_lang_subtrees "$SHARED_DIR" "shared"

finish
