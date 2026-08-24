#!/usr/bin/env bash
# lib.sh — assertion helpers and frontmatter parsing for L1 static checks.

PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); echo "    ok: $*"; }
fail() { FAIL=$((FAIL + 1)); echo "    FAIL: $*" >&2; }

finish() {
  echo "  -> $PASS passed, $FAIL failed"
  [ "$FAIL" -eq 0 ]
}

is_kebab() { [[ "$1" =~ ^[a-z][a-z0-9]*(-[a-z0-9]+)*$ ]]; }

# YAML frontmatter block between the leading --- markers
fm_block() {
  awk 'NR==1 { if ($0 != "---") exit } NR>1 { if ($0 == "---") exit; print }' "$1"
}

# scalar value of a frontmatter key
fm_scalar() {
  fm_block "$1" | awk -F': ' -v k="$2" '$1 == k { sub(/^[^:]*: */, ""); print; exit }'
}

# list values of a frontmatter key — supports both forms:
#   key:        key: [a, b]
#     - a
fm_list() {
  local file=$1 key=$2
  fm_block "$file" | awk -v k="$key" '
    $0 == k ":" { inlist = 1; next }
    inlist && /^  - / { sub(/^  - /, ""); print; next }
    inlist && /^[^ ]/ { inlist = 0 }
  '
  fm_block "$file" | awk -F': ' -v k="$2" '
    $1 == k && $2 ~ /^\[/ {
      gsub(/^\[|\]$/, "", $2)
      n = split($2, a, ",")
      for (i = 1; i <= n; i++) { gsub(/^ +| +$/, "", a[i]); print a[i] }
    }
  '
}
