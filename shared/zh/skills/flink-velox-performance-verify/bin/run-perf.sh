#!/usr/bin/env bash
# run-perf.sh — run one nexmark benchmark query at a given parallelism and
# object-reuse setting on the currently running cluster, and capture the
# runner's summary metrics table.
#
# Usage: run-perf.sh {native|gfv} <qNN> <p> <true|false> <out-file>
#   The mode tag is recorded in the log line only; both modes submit to the
#   currently running cluster. The caller is responsible for which build the
#   cluster runs (restart via the flink-velox-build skill between the native
#   and gfv rounds).
#
#   GFV hard rule: pipeline.object-reuse=true crashes the GFV stack — the
#   gfv+true combination is rejected outright.
#
# Fixed benchmark parameters live in two conf files this script manages for
# the duration of the run and RESTORES afterwards (also on failure or
# interrupt; originals are kept as *.gfvbot.bak next to the conf):
#   $NEXMARK_HOME/conf/nexmark.yaml    replaced whole by this skill's
#                                      conf/nexmark-gfv.yaml (1e8 events,
#                                      5e7 tps suite)
#   $FLINK_HOME/conf/flink-conf.yaml   parallelism.default and
#                                      pipeline.object-reuse set/updated
#
# Capture model: nexmark queries sink to blackhole — there is no changelog
# to collect. The benchmark runner prints a "Nexmark Results" summary table
# on stderr when the job finishes; the merged runner output is saved whole
# as <out>.submit.log and the table is extracted from it into <out>.
#
# Exit non-zero when the runner itself fails.
set -euo pipefail

usage='usage: run-perf.sh {native|gfv} <qNN> <p> <true|false> <out-file>'
mode="${1:?$usage}"
query="${2:?$usage}"
par="${3:?$usage}"
reuse="${4:?$usage}"
out="${5:?$usage}"

case "$mode" in native|gfv) ;; *) echo "$usage" >&2; exit 1 ;; esac
case "$reuse" in true|false) ;; *) echo "$usage" >&2; exit 1 ;; esac
case "$par" in ''|*[!0-9]*|0) echo "p must be a positive integer, got: $par" >&2; exit 1 ;; esac
if [ "$mode" = gfv ] && [ "$reuse" = true ]; then
  # object-reuse=true crashes the GFV stack; GFV runs are reuse=false only.
  echo "gfv + object-reuse=true is not supported (crashes) — run gfv with reuse=false" >&2
  exit 1
fi

# Locate .gfvbot/env.json by walking upward from this script (adapter
# layouts differ in depth; the archive marks the workspace root).
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skill_dir="$(dirname "$here")"
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

FLINK_HOME="$(jq -r '.stack.flink.path // empty' "$env_json")"
[ -n "$FLINK_HOME" ] || { echo "flink installation not recorded in env.json — run 'gfvbot env'" >&2; exit 1; }
export FLINK_HOME   # nexmark's bin/config.sh builds its classpath from it

# nexmark.home is recorded only by newer env.sh versions — fall back to the
# installer default when empty, then require the runner to be there.
NEXMARK_HOME="$(jq -r '.stack.nexmark.home // empty' "$env_json")"
[ -n "$NEXMARK_HOME" ] || NEXMARK_HOME="/opt/nexmark"
[ -x "$NEXMARK_HOME/bin/run_query.sh" ] || { echo "nexmark runner not found: $NEXMARK_HOME/bin/run_query.sh — run 'gfvbot env'" >&2; exit 1; }

flink_conf="$FLINK_HOME/conf/flink-conf.yaml"
nexmark_conf="$NEXMARK_HOME/conf/nexmark.yaml"
fixed_conf="$skill_dir/conf/nexmark-gfv.yaml"
[ -f "$flink_conf" ] || { echo "flink conf not found: $flink_conf" >&2; exit 1; }
[ -f "$nexmark_conf" ] || { echo "nexmark conf not found: $nexmark_conf" >&2; exit 1; }
[ -f "$fixed_conf" ] || { echo "skill fixed suite conf not found: $fixed_conf" >&2; exit 1; }

# slot check: total slots = #workers (deduped, comments stripped) x
# taskmanager.numberOfTaskSlots (flink-conf, default 1)
tms=1
if [ -f "$FLINK_HOME/conf/workers" ]; then
  tms=$(grep -vE '^[[:space:]]*(#|$)' "$FLINK_HOME/conf/workers" \
        | cut -d'#' -f1 | awk '{print $1}' | sort -u | grep -c .) || tms=0
  [ "$tms" -gt 0 ] || tms=1
fi
slots=$({ grep -E '^taskmanager\.numberOfTaskSlots:' "$flink_conf" || true; } \
        | tail -1 | sed 's/^taskmanager\.numberOfTaskSlots:[[:space:]]*//; s/[[:space:]]*$//')
[ -n "$slots" ] || slots=1
total=$((tms * slots))
if [ "$par" -gt "$total" ]; then
  echo "parallelism p=$par exceeds cluster slots (tms=$tms x slots=$slots = $total) — raise taskmanager.numberOfTaskSlots and restart the cluster first" >&2
  exit 1
fi

# --- conf management: swap in the fixed benchmark confs, restore on exit ---
nexmark_bak="$nexmark_conf.gfvbot.bak"
flink_bak="$flink_conf.gfvbot.bak"
restore_confs() {
  [ -f "$nexmark_bak" ] && mv -f "$nexmark_bak" "$nexmark_conf"
  [ -f "$flink_bak" ] && mv -f "$flink_bak" "$flink_conf"
  return 0
}
trap restore_confs EXIT INT TERM

cp -p "$nexmark_conf" "$nexmark_bak"
cp "$fixed_conf" "$nexmark_conf"

cp -p "$flink_conf" "$flink_bak"
set_conf_key() {  # <key> <value> — replace the existing line or append
  local key=$1 val=$2
  if grep -qE "^${key}:" "$flink_conf"; then
    sed -i -E "s|^${key}:.*|${key}: ${val}|" "$flink_conf"
  else
    printf '%s: %s\n' "$key" "$val" >>"$flink_conf"
  fi
}
set_conf_key parallelism.default "$par"
set_conf_key pipeline.object-reuse "$reuse"

out_dir="$(dirname "$out")"
mkdir -p "$out_dir"

submit_log="${out%.out}.submit.log"
status=0
"$NEXMARK_HOME/bin/run_query.sh" oa "$query" >"$submit_log" 2>&1 || status=$?
if [ "$status" -ne 0 ]; then
  echo "[$mode] runner failed (exit $status) — see $submit_log" >&2
  exit 1
fi

# keep the summary table: from the "Nexmark Results" banner to EOF.
# scratch stays next to the capture — never in /tmp.
tmp="$out.tmp"
awk '/Nexmark Results/{f=1} f' "$submit_log" >"$tmp"
mv "$tmp" "$out"

rows=$(grep -c '^|' "$out" || true)
# Banner-missing self-check: a successful run that produced no summary table
# is almost always a job that never reached FINISHED — fail loud instead of
# letting an empty table feed the comparison.
if [ "$rows" -eq 0 ]; then
  echo "[$mode] WARNING: no \"Nexmark Results\" table captured — check $submit_log; confirm the job reached FINISHED" >&2
fi
echo "[$mode] $query p=$par reuse=$reuse: captured $rows table lines -> $out (confs restored on exit)"
echo "confirm the job reached FINISHED before trusting the metrics"
