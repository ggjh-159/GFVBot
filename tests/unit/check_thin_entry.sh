#!/usr/bin/env bash
# check_thin_entry.sh — L1: every plugins/<name>/install.sh must be the
# standard thin entry, byte-identical across plugins and forwarding to the
# engine (no plugin-specific install logic).

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$TESTS_DIR/lib.sh"
ROOT="$(cd "$TESTS_DIR/../.." && pwd)"
PLUGINS_DIR="$ROOT/plugins"

n=0
unique=$(md5sum "$PLUGINS_DIR"/*/install.sh 2>/dev/null | awk '{print $1}' | sort -u | wc -l)
n=$(ls -d "$PLUGINS_DIR"/*/ | wc -l)

if [ "$unique" = "1" ] && [ "$n" -gt 0 ]; then
  pass "all $n thin entries byte-identical"
else
  fail "thin entries diverge ($unique distinct checksums across $n plugins)"
fi

first=$(ls -d "$PLUGINS_DIR"/*/ | head -1)
if grep -q '^exec ' "$first/install.sh" && grep -q 'installer/install.sh' "$first/install.sh"; then
  pass "thin entry forwards to installer engine"
else
  fail "thin entry does not forward to installer/install.sh"
fi

finish
