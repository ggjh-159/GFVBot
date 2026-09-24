#!/bin/bash
# layer-dep-check.sh — check gluten-flink layer dependency violations.
# Usage: bash scripts/layer-dep-check.sh <workspace-root>
#
# The workspace root is the GFV workspace whose module trees live under repos/
# (laid down by `gfvbot clone`): repos/gluten/gluten-flink and repos/velox4j.
#
# Rules:
#   1. planner must not import runtime internal implementation classes
#   2. runtime must not import planner classes
#   3. velox4j public API must not expose internal implementation

set -euo pipefail

ROOT_DIR="${1:-.}"
PLANNER_DIR="${ROOT_DIR}/repos/gluten/gluten-flink/planner"
RUNTIME_DIR="${ROOT_DIR}/repos/gluten/gluten-flink/runtime"
ERRORS=0

echo "=== Layer Dependency Check ==="
echo ""

# Rule 1: planner must not import runtime internals. The streaming.api
# packages are the public cross-layer interface, so they are exempt.
echo "[CHECK] planner -> runtime internal imports..."
if [ -d "$PLANNER_DIR" ]; then
    VIOLATIONS=$(grep -rn \
        "import org.apache.gluten.streaming\." \
        "$PLANNER_DIR" --include="*.java" 2>/dev/null \
        | grep -v "org.apache.gluten.streaming\.api\." || true)
    VIOLATIONS2=$(grep -rn \
        "import org.apache.gluten.vectorized\." \
        "$PLANNER_DIR" --include="*.java" 2>/dev/null || true)
    VIOLATIONS3=$(grep -rn \
        "import org.apache.gluten.client\." \
        "$PLANNER_DIR" --include="*.java" 2>/dev/null || true)

    if [ -n "$VIOLATIONS" ] || [ -n "$VIOLATIONS2" ] || [ -n "$VIOLATIONS3" ]; then
        echo "  [FAIL] planner directly depends on runtime internals:"
        [ -n "$VIOLATIONS" ]  && echo "$VIOLATIONS"
        [ -n "$VIOLATIONS2" ] && echo "$VIOLATIONS2"
        [ -n "$VIOLATIONS3" ] && echo "$VIOLATIONS3"
        ERRORS=$((ERRORS + 1))
    else
        echo "  [PASS]"
    fi
else
    echo "  [SKIP] planner directory not found"
fi

# Rule 2: runtime must not import planner classes.
echo "[CHECK] runtime -> planner imports..."
if [ -d "$RUNTIME_DIR" ]; then
    VIOLATIONS=$(grep -rn \
        "import org.apache.gluten.rexnode\." \
        "$RUNTIME_DIR" --include="*.java" 2>/dev/null || true)
    VIOLATIONS2=$(grep -rn \
        "import org.apache.gluten.velox\." \
        "$RUNTIME_DIR" --include="*.java" 2>/dev/null || true)

    if [ -n "$VIOLATIONS" ] || [ -n "$VIOLATIONS2" ]; then
        echo "  [FAIL] runtime directly depends on planner classes:"
        [ -n "$VIOLATIONS" ]  && echo "$VIOLATIONS"
        [ -n "$VIOLATIONS2" ] && echo "$VIOLATIONS2"
        ERRORS=$((ERRORS + 1))
    else
        echo "  [PASS]"
    fi
else
    echo "  [SKIP] runtime directory not found"
fi

# Rule 3: velox4j public API must not expose internals.
echo "[CHECK] velox4j public API exposing internals..."
VELOX4J_PUBLIC="${ROOT_DIR}/repos/velox4j/src/main/java/io/github/zhztheplayer/velox4j"
if [ -d "$VELOX4J_PUBLIC" ]; then
    VIOLATIONS=$(grep -rn \
        "import io.github.zhztheplayer.velox4j.internal\." \
        "${VELOX4J_PUBLIC}" --include="*.java" 2>/dev/null || true)
    if [ -n "$VIOLATIONS" ]; then
        echo "  [FAIL] velox4j public API references internal packages:"
        echo "$VIOLATIONS"
        ERRORS=$((ERRORS + 1))
    else
        echo "  [PASS]"
    fi
else
    echo "  [SKIP] velox4j directory not found"
fi

echo ""
if [ "$ERRORS" -eq 0 ]; then
    echo "=== All checks passed ==="
    exit 0
else
    echo "=== $ERRORS check(s) failed ==="
    exit 1
fi
