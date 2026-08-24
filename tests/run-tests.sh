#!/usr/bin/env bash
# run-tests.sh — GFVBot test entry.
#
# Modes:
#   --fast        (default) L1 static checks, no CLI needed, seconds
#   --incremental L1 limited to changed plugins/shared (git diff vs HEAD);
#                 falls back to full run when there is no commit history
#   --e2e         installer lifecycle smoke in a disposable sandbox
#   --behavior    L2 behavior tests (need claude/opencode CLI)

set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

MODE=fast
for arg in "$@"; do
  case "$arg" in
    --fast|--incremental|--behavior) MODE="${arg#--}" ;;
    --e2e) exec bash "$ROOT/tests/e2e/run-e2e.sh" ;;
    *) echo "unknown option: $arg"; exit 1 ;;
  esac
done

case "$MODE" in
  behavior)
    echo "L2 behavior tests are not built yet (require claude/opencode CLI)"
    exit 0
    ;;
  incremental)
    if ! git -C "$ROOT" rev-parse --verify HEAD >/dev/null 2>&1; then
      echo "incremental: no commit history, running full L1 suite"
    elif [ -z "$(git -C "$ROOT" diff --name-only HEAD -- plugins shared 2>/dev/null)" ]; then
      echo "incremental: no changes under plugins/ or shared/, nothing to check"
      exit 0
    fi
    ;;
esac

echo "=== GFVBot L1 static checks ($MODE) ==="
rc=0
for check in "$ROOT"/tests/unit/check_*.sh; do
  echo "--- $(basename "$check")"
  bash "$check" || rc=1
done
if [ "$rc" = 0 ]; then
  echo "=== all L1 checks passed ==="
else
  echo "=== L1 checks FAILED ==="
fi
exit "$rc"
