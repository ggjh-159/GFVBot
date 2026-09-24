#!/bin/bash
# anti-pattern-grep.sh — scan for common Flink-Velox anti-patterns.
# Usage: bash scripts/anti-pattern-grep.sh <workspace-root> [changed-files]
#
# The workspace root is the GFV workspace whose module trees live under repos/
# (laid down by `gfvbot clone`): repos/gluten/gluten-flink, repos/velox4j,
# repos/velox. When a changed-file list is given (space-separated paths or a
# file containing them, relative to the workspace root), only those files are
# scanned.
#
# Checks:
#   1. Arrow Vector used outside try-with-resources
#   2. empty catch blocks
#   3. uninitialized variables used directly (C++)
#   4. object allocation in hot paths
#   5. magic numbers

set -euo pipefail

ROOT_DIR="${1:-.}"
CHANGED_FILES="${2:-}"
ERRORS=0
WARNINGS=0

# When CHANGED_FILES is a file path, read the list from it.
if [ -n "$CHANGED_FILES" ] && [ -f "$CHANGED_FILES" ]; then
    CHANGED_FILES=$(cat "$CHANGED_FILES" | tr '\n' ' ')
fi

echo "=== Anti-Pattern Grep ==="
[ -n "$CHANGED_FILES" ] && echo "[FILTER] scanning changed files only"
echo ""

# Build the grep target list: the changed files when a filter is given,
# otherwise the module directories themselves.
build_grep_targets() {
    local suffix="$1"
    local dirs=("$@")
    dirs=("${dirs[@]:1}")

    if [ -n "$CHANGED_FILES" ]; then
        # Keep only the changed files matching the suffix.
        local targets=""
        for f in $CHANGED_FILES; do
            if echo "$f" | grep -qE "\.${suffix}$"; then
                local fullpath="${ROOT_DIR}/${f}"
                [ -f "$fullpath" ] && targets="${targets}${fullpath} "
            fi
        done
        echo "$targets"
    else
        for d in "${dirs[@]}"; do
            echo "${d}"
        done
    fi
}

# --- Java checks ---
JAVA_DIRS=()
[ -d "${ROOT_DIR}/repos/gluten/gluten-flink" ] && JAVA_DIRS+=("${ROOT_DIR}/repos/gluten/gluten-flink")
[ -d "${ROOT_DIR}/repos/velox4j" ] && JAVA_DIRS+=("${ROOT_DIR}/repos/velox4j")

if [ ${#JAVA_DIRS[@]} -gt 0 ]; then
    JAVA_TARGETS=$(build_grep_targets "java" "${JAVA_DIRS[@]}")

    if [ -n "$JAVA_TARGETS" ]; then
        # Check 1: empty catch blocks.
        echo "[CHECK] Empty catch blocks..."
        FOUND=$(grep -rn "catch.*{" $JAVA_TARGETS -A1 2>/dev/null \
            | grep -E "^\s*}" 2>/dev/null || true)
        if [ -n "$FOUND" ]; then
            echo "  [WARN] possible empty catch blocks:"
            echo "$FOUND"
            WARNINGS=$((WARNINGS + 1))
        else
            echo "  [PASS]"
        fi

        # Check 2: VectorSchemaRoot outside try-with-resources.
        echo "[CHECK] Arrow Vector without try-with-resources..."
        FOUND=$(grep -rn "VectorSchemaRoot\.\(create\|open\)" $JAVA_TARGETS -B2 2>/dev/null \
            | grep -v "try (" 2>/dev/null \
            | grep "VectorSchemaRoot" 2>/dev/null || true)
        if [ -n "$FOUND" ]; then
            echo "  [WARN] Arrow Vector possibly outside try-with-resources:"
            echo "$FOUND"
            WARNINGS=$((WARNINGS + 1))
        else
            echo "  [PASS]"
        fi

        # Check 3: object allocation inside processElement.
        echo "[CHECK] Object allocation in processElement..."
        FOUND=$(grep -rn "void processElement" $JAVA_TARGETS -A20 2>/dev/null \
            | grep "new " 2>/dev/null || true)
        if [ -n "$FOUND" ]; then
            echo "  [WARN] possible unnecessary allocations in processElement:"
            echo "$FOUND"
            WARNINGS=$((WARNINGS + 1))
        else
            echo "  [PASS]"
        fi

        # Check 4: magic numbers (bare literals other than 0/1/-1).
        echo "[CHECK] Magic numbers in comparisons..."
        FOUND=$(grep -rn "== [2-9][0-9]*\|>= [2-9][0-9]*\|<= [2-9][0-9]*\|!= [2-9][0-9]*" \
            $JAVA_TARGETS 2>/dev/null || true)
        if [ -n "$FOUND" ]; then
            FOUND_COUNT=$(echo "$FOUND" | wc -l)
            if [ "$FOUND_COUNT" -gt 20 ]; then
                echo "  [INFO] ${FOUND_COUNT} possible magic numbers (showing first 10):"
                echo "$FOUND" | head -10
            else
                echo "  [INFO] ${FOUND_COUNT} possible magic numbers:"
                echo "$FOUND"
            fi
        else
            echo "  [PASS]"
        fi
    else
        echo "[SKIP] no Java files among changed files"
    fi
fi

# --- C++ checks ---
CPP_DIR="${ROOT_DIR}/repos/velox"
if [ -d "$CPP_DIR" ]; then
    CPP_TARGETS=$(build_grep_targets "cpp" "$CPP_DIR")
    CPP_H_TARGETS=$(build_grep_targets "h" "$CPP_DIR")
    ALL_CPP_TARGETS="${CPP_TARGETS} ${CPP_H_TARGETS}"
    ALL_CPP_TARGETS=$(echo "$ALL_CPP_TARGETS" | xargs 2>/dev/null || true)

    if [ -n "$ALL_CPP_TARGETS" ]; then
        # Check 5: uninitialized variables (declaration followed by direct use; heuristic).
        echo "[CHECK] Potentially uninitialized variables (C++)..."
        FOUND=$(grep -rn "int [a-zA-Z_]*;" $ALL_CPP_TARGETS 2>/dev/null \
            | grep -v "= " 2>/dev/null \
            | grep -v "extern\|const\|static\|constexpr\|function\|return\|//\|int i\|int j\|int k\|int n\|int x\|int y" \
            2>/dev/null | head -20 || true)
        if [ -n "$FOUND" ]; then
            FOUND_COUNT=$(echo "$FOUND" | wc -l)
            echo "  [INFO] ${FOUND_COUNT} possibly uninitialized int variables (showing first 20):"
            echo "$FOUND"
        else
            echo "  [PASS]"
        fi
    else
        echo "[SKIP] no C++ files among changed files"
    fi
else
    echo "[SKIP] velox directory not found, skipping C++ checks"
fi

echo ""
echo "=== Summary: ${ERRORS} error(s), ${WARNINGS} warning(s) ==="
exit "$ERRORS"
