#!/usr/bin/env bash
# format.sh — run the canonical format check (or fix) of the repo that owns
# the changed files, so every plugin shares one machine verdict.
#
# Usage: format.sh {check|fix} <repo-path> [--base <git-ref>] [--kind velox|velox4j|gluten]
#
#   check   exit 1 and list offending files when any changed file violates
#           the repo's format; exit 0 and print only the verdict when clean
#   fix     apply the repo's formatter to the changed files; velox uses the
#           fork's own `make format-fix`, which stages everything first
#           because its check.py refuses unstaged changes
#
# Repo kinds and their canonical entries (the repos' own tooling, as
# recorded in the flink-velox-review-response skill):
#   velox    C/C++: per-file `clang-format --dry-run --Werror` (check) /
#            `git add -A && make format-fix CHECK_BASE=<base>` (fix)
#   velox4j  Java:  `mvn -q spotless:check` / `mvn -q spotless:apply`
#   gluten   C/C++: per-file clang-format (check) / `clang-format -i` (fix);
#            Java:  at the gluten-flink/ root,
#                   `mvn -q spotless:check -pl planner,ut` / `... spotless:apply -pl planner,ut`
#
# Changed files = uncommitted work (staged + unstaged + untracked), which is
# what gets committed next; `--base <git-ref>` adds every file changed since
# that ref. The spotless checks cover whole modules, so their output may
# list files outside this change set — pre-existing repo debt, not yours.
#
# Exit: 0 clean / applied, 1 violations (check) or tool failure (fix),
#       2 usage or environment error.
set -euo pipefail

usage='usage: format.sh {check|fix} <repo-path> [--base <git-ref>] [--kind velox|velox4j|gluten]'
[ $# -ge 2 ] || { echo "$usage" >&2; exit 2; }
mode="$1"
repo="$2"
shift 2
base=""
kind=""
while [ $# -gt 0 ]; do
  case "$1" in
    --base) base="${2:?--base needs a ref}"; shift 2 ;;
    --kind) kind="${2:?--kind needs velox|velox4j|gluten}"; shift 2 ;;
    *) echo "$usage" >&2; exit 2 ;;
  esac
done
case "$mode" in check|fix) ;; *) echo "$usage" >&2; exit 2 ;; esac
[ -d "$repo/.git" ] || git -C "$repo" rev-parse --git-dir >/dev/null 2>&1 \
  || { echo "not a git repository: $repo" >&2; exit 2; }
repo="$(cd "$repo" && pwd)"

# --- repo kind: explicit flag wins, otherwise detected from layout --------
if [ -z "$kind" ]; then
  if [ -d "$repo/gluten-flink" ]; then kind=gluten
  elif [ -d "$repo/velox" ] && [ -f "$repo/.clang-format" ]; then kind=velox
  elif [ -f "$repo/pom.xml" ] && { [ "$(basename "$repo")" = velox4j ] || [ -d "$repo/velox4j" ]; }; then kind=velox4j
  else
    echo "cannot detect the repo kind from $repo — pass --kind velox|velox4j|gluten" >&2
    exit 2
  fi
fi

# --- changed files -----------------------------------------------------------
changed() {
  { [ -n "$base" ] && git -C "$repo" diff --name-only "$base"...HEAD 2>/dev/null || true
    git -C "$repo" diff --name-only --cached 2>/dev/null || true
    git -C "$repo" diff --name-only 2>/dev/null || true
    git -C "$repo" ls-files --others --exclude-standard 2>/dev/null || true
  } | sort -u | grep -v '/$' || true
}
all_changed="$(changed)"
cxx="$(printf '%s\n' "$all_changed" | grep -E '\.(h|hpp|hxx|c|cc|cpp|cxx)$' || true)"
java="$(printf '%s\n' "$all_changed" | grep -E '\.java$' || true)"
if [ -z "$all_changed" ]; then
  echo "no changed files under $repo (uncommitted$( [ -n "$base" ] && printf ' + since %s' "$base"))"
  exit 0
fi

# --- per-kind dispatch --------------------------------------------------------
# The velox format-fix target is the fork's own entry: check.py refuses
# unstaged changes, so everything is staged first (the documented procedure).
velox_default_base="${VELOX_CHECK_BASE:-gluten-20260829}"

check_cxx() {  # <workdir> <files...>
  command -v clang-format >/dev/null 2>&1 || { echo "clang-format not found in PATH — install the version the repo's CI uses" >&2; exit 2; }
  local wd=$1; shift
  [ $# -gt 0 ] || return 0
  ( cd "$wd" && clang-format --dry-run --Werror "$@" )
}

check_java() {  # <module-dir> <mvn args...>
  command -v mvn >/dev/null 2>&1 || { echo "mvn not found in PATH" >&2; exit 2; }
  local wd=$1; shift
  ( cd "$wd" && mvn -q spotless:check "$@" )
}

rc=0
case "$kind" in
  velox)
    if [ "$mode" = check ]; then
      # shellcheck disable=SC2086
      check_cxx "$repo" $cxx || rc=1
    else
      if [ -n "$cxx" ]; then
        echo "velox fix stages every change (git add -A) before make format-fix — check.py refuses unstaged work"
        git -C "$repo" add -A
        ( cd "$repo" && make format-fix "CHECK_BASE=${base:-$velox_default_base}" ) || rc=1
      fi
    fi
    ;;
  velox4j)
    if [ "$mode" = check ]; then
      [ -n "$java" ] && { check_java "$repo" || rc=1; }
    else
      [ -n "$java" ] && { ( cd "$repo" && mvn -q spotless:apply ) || rc=1; }
    fi
    ;;
  gluten)
    if [ "$mode" = check ]; then
      # shellcheck disable=SC2086
      [ -n "$cxx" ] && { check_cxx "$repo" $cxx || rc=1; }
      [ -n "$java" ] && { check_java "$repo/gluten-flink" -pl planner,ut || rc=1; }
    else
      if [ -n "$cxx" ]; then
        command -v clang-format >/dev/null 2>&1 || { echo "clang-format not found in PATH" >&2; exit 2; }
        # shellcheck disable=SC2086
        ( cd "$repo" && clang-format -i $cxx )
      fi
      [ -n "$java" ] && { ( cd "$repo/gluten-flink" && mvn -q spotless:apply -pl planner,ut ) || rc=1; }
    fi
    ;;
  *) echo "unknown repo kind: $kind (velox|velox4j|gluten)" >&2; exit 2 ;;
esac

if [ "$mode" = check ]; then
  if [ "$rc" -eq 0 ]; then
    echo "FORMAT CHECK: clean ($kind; $(printf '%s\n' "$all_changed" | wc -l) changed files considered)"
  else
    echo "FORMAT CHECK: violations found ($kind) — run 'format.sh fix' on the repo, then re-run check, recompile, and re-run unit tests" >&2
  fi
else
  [ "$rc" -eq 0 ] && echo "FORMAT FIX: applied ($kind) — re-run 'format.sh check', then recompile and re-run unit tests"
fi
exit "$rc"
