#!/usr/bin/env bash
# check_dryrun.sh — L1: install --dry-run must not touch the target and must
# report what it would do.

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
  out=$(bash "$ROOT/installer/install.sh" --plugin "$p" --tool claude --target "$TMP" --dry-run 2>&1)
  rc=$?
  if [ "$rc" != 0 ]; then
    fail "$p: dry-run exited $rc"
    continue
  fi
  if [ -e "$TMP/.gfvbot" ] || [ -e "$TMP/.claude" ] || [ -e "$TMP/CLAUDE.md" ] || [ -e "$TMP/AGENTS.md" ]; then
    fail "$p: dry-run wrote into target"
    continue
  fi
  if echo "$out" | grep -q '\[dry-run\]'; then
    pass "$p: dry-run clean, plan reported"
  else
    fail "$p: dry-run reported no plan lines"
  fi
done

finish
