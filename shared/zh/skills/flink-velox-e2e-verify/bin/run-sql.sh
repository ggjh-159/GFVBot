#!/usr/bin/env bash
# run-sql.sh — submit one SQL case file to a Flink cluster and capture the
# print-sink changelog rows it produced.
#
# Usage: run-sql.sh {native|gfv} <case.sql> <out-file>
#   The mode tag is recorded in the log line only; both modes submit to the
#   currently running cluster. The caller is responsible for which build the
#   cluster runs (restart via the flink-velox-build skill before a GFV run).
#
# Capture model: snapshot every TaskManager .out file's line count before
# submission, then keep only the lines appended after it (new .out files are
# taken whole). Duplicate rows are PRESERVED — the changelog fold in
# changelog_diff.py treats output as a multiset. At parallelism > 1 the print
# sink prefixes each row with its subtask id ("3> +I[...]"); the prefix is
# stripped during capture so downstream sees pure FLAG[payload] rows.
#
# Exit non-zero when the submission itself fails.
set -euo pipefail

mode="${1:?usage: run-sql.sh {native|gfv} <case.sql> <out-file>}"
sql="${2:?usage: run-sql.sh {native|gfv} <case.sql> <out-file>}"
out="${3:?usage: run-sql.sh {native|gfv} <case.sql> <out-file>}"
[ -f "$sql" ] || { echo "case sql not found: $sql" >&2; exit 1; }

# Locate .gfvbot/env.json by walking upward from this script (adapter
# layouts differ in depth; the archive marks the workspace root).
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
env_json=""
search_dir="$here"
while [ "$search_dir" != "/" ]; do
  if [ -f "$search_dir/.gfvbot/env.json" ]; then
    env_json="$search_dir/.gfvbot/env.json"
    break
  fi
  search_dir="$(dirname "$search_dir")"
done
[ -n "$env_json" ] || { echo "missing .gfvbot/env.json — run 'gfvbot env' first" >&2; exit 1; }

FLINK_HOME="$(jq -r '.FLINK_HOME // empty' "$env_json")"
[ -n "$FLINK_HOME" ] || { echo "FLINK_HOME not recorded in env.json" >&2; exit 1; }
log_dir="$FLINK_HOME/log"
mkdir -p "$log_dir"

# snapshot: "<path>:<linecount>" for existing .out files
snapshot() { for f in "$log_dir"/*.out; do [ -f "$f" ] && printf '%s:%s\n' "$f" "$(wc -l <"$f")"; done 2>/dev/null || true; }
before="$(snapshot)"

submit_log="${out%.out}.submit.log"
if ! "$FLINK_HOME/bin/sql-client.sh" -f "$sql" >"$submit_log" 2>&1; then
  echo "[$mode] submission failed — see $submit_log" >&2
  exit 1
fi

: >"$out"
# appended lines of pre-existing files, then whole new files
while IFS=: read -r f n; do
  [ -f "$f" ] || continue
  awk -v n="$n" 'NR>n' "$f" >>"$out"
done <<<"$before"
for f in "$log_dir"/*.out; do
  [ -f "$f" ] || continue
  case "$before" in *"$f:"*) continue ;; esac
  cat "$f" >>"$out"
done 2>/dev/null || true

# keep only changelog rows, in arrival order; strip any subtask-id prefix
# ("3> +I[...]") so the fold downstream sees pure FLAG[payload] rows.
# scratch stays next to the capture — never in /tmp.
tmp="$out.tmp"
grep -E '^([0-9]+> )?[-+][IUD]\[' "$out" | sed -E 's/^[0-9]+> //' >"$tmp" || true
mv "$tmp" "$out"

rows=$(wc -l <"$out")
echo "[$mode] $(basename "$sql"): captured $rows changelog rows -> $out"
echo "confirm the job reached FINISHED before trusting the capture"
