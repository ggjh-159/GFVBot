#!/usr/bin/env bash
# check_dryrun.sh — L1: install --dry-run must not touch the target, must
# report what it would do, and must land language-neutral paths for every
# content language (the en/ zh/ source trees are stripped on landing).

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$TESTS_DIR/lib.sh"
ROOT="$(cd "$TESTS_DIR/../.." && pwd)"
PLUGINS_DIR="$ROOT/plugins"
export GFVBOT_LANG=en

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

for d in "$PLUGINS_DIR"/*/; do
  p=$(basename "$d")
  for lang in en zh; do
    out=$(bash "$ROOT/installer/install.sh" --plugin "$p" --tool claude --target "$TMP" --dry-run --lang "$lang" 2>&1)
    rc=$?
    if [ "$rc" != 0 ]; then
      fail "$p($lang): dry-run exited $rc"
      continue
    fi
    if [ -e "$TMP/.gfvbot" ] || [ -e "$TMP/.claude" ] || [ -e "$TMP/CLAUDE.md" ] || [ -e "$TMP/AGENTS.md" ]; then
      fail "$p($lang): dry-run wrote into target"
      continue
    fi
    if ! echo "$out" | grep -q '\[dry-run\]'; then
      fail "$p($lang): dry-run reported no plan lines"
      continue
    fi
    # landing paths must be language-neutral: no en/ or zh/ segment may
    # survive into any destination the plan reports
    bad=$(printf '%s\n' "$out" | sed -n 's/.*-> //p' | grep -E '/(en|zh)/')
    if [ -n "$bad" ]; then
      fail "$p($lang): language layer leaks into landing path: $(echo "$bad" | head -1)"
    else
      pass "$p($lang): dry-run clean, plan reported, landing paths neutral"
    fi
  done
done

finish
