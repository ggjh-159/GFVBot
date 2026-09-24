#!/bin/bash
# diff-parser.sh — parse a diff / git diff and extract the change surface.
# Usage: bash scripts/diff-parser.sh <diff-file>
# Output: change-surface analysis as JSON (file list, inferred languages, inferred tags).
#
# Example output:
# {
#   "files": ["runtime/src/.../Foo.java"],
#   "tags": ["arrow-res", "exception"],
#   "languages": ["java"]
# }

set -euo pipefail

DIFF_FILE="${1:-/dev/stdin}"

# Read from a file path, or from stdin when the argument is "-" or not a file.
if [ "$DIFF_FILE" = "-" ] || [ ! -f "$DIFF_FILE" ]; then
    DIFF_CONTENT=$(cat)
else
    DIFF_CONTENT=$(cat "$DIFF_FILE")
fi

# Extract the changed file list (git diff and unified diff formats both supported).
FILES=$(echo "$DIFF_CONTENT" | grep -E "^(diff --git |\+\+\+ |--- )" \
    | sed 's|^diff --git a/||; s|^diff --git b/||; s|^+++ [^/]*||; s|^--- [^/]*||' \
    | grep -v "^dev/null$" \
    | sort -u || true)

# Infer languages.
LANGUAGES=""
if echo "$FILES" | grep -q "\.java$"; then
    LANGUAGES="${LANGUAGES}java "
fi
if echo "$FILES" | grep -qE "\.(cpp|h|cc|hpp)$"; then
    LANGUAGES="${LANGUAGES}cpp "
fi
if echo "$FILES" | grep -q "\.scala$"; then
    LANGUAGES="${LANGUAGES}scala "
fi

# Infer change tags from keywords in the diff content.
TAGS=""

# Arrow resource handling.
if echo "$DIFF_CONTENT" | grep -qiE "(VectorSchemaRoot|FieldVector|ArrowVector|BufferAllocator|Session|QueryResult|close\(\)|allocateNew)"; then
    TAGS="${TAGS}arrow-res "
fi

# Exception handling.
if echo "$DIFF_CONTENT" | grep -qiE "(try\s*\{|catch\s*\(|throw\s|finally\s*\{|Exception|Error)"; then
    TAGS="${TAGS}exception "
fi

# JSON serialization.
if echo "$DIFF_CONTENT" | grep -qiE "(VeloxPlan|VeloxExpression|@Json|ObjectMapper|serialize|deserialize)"; then
    TAGS="${TAGS}json-serde "
fi

# RexCall conversion.
if echo "$DIFF_CONTENT" | grep -qiE "(RexCallConverter|RexNode|RexCall)"; then
    TAGS="${TAGS}rexcall "
fi

# Operator lifecycle.
if echo "$DIFF_CONTENT" | grep -qiE "(extends.*Operator|open\(\)|close\(\)|dispose\(\)|processElement|processWatermark)"; then
    TAGS="${TAGS}operator "
fi

# C++ pointer handling.
if echo "$DIFF_CONTENT" | grep -qiE "(dynamic_cast|static_cast|reinterpret_cast|\*\w+|new\s|delete\s|nullptr|NULL)"; then
    TAGS="${TAGS}pointer "
fi

# Numeric arithmetic.
if echo "$DIFF_CONTENT" | grep -qiE "(/\s*\w+|%\s*\w+|\[\w+\]|INT_MAX|INT_MIN|size_t|int64_t)"; then
    TAGS="${TAGS}numeric "
fi

# Import-only changes.
if echo "$DIFF_CONTENT" | grep -qiE "^(\+|-)import "; then
    TAGS="${TAGS}import "
fi

# Public API changes.
if echo "$DIFF_CONTENT" | grep -qiE "(public\s+(static\s+)?\w+\s+\w+\s*\(|interface\s+\w+|@Deprecated)"; then
    TAGS="${TAGS}api-change "
fi

# Fall back to "other" when nothing matched.
if [ -z "$TAGS" ]; then
    TAGS="other "
fi

# Emit JSON.
FILES_JSON=$(echo "$FILES" | grep -v "^$" | sed 's|^|    "|; s|$|"|' | paste -sd ",\n" - || echo "")

printf '{\n'
printf '  "files": [\n'
if [ -n "$FILES_JSON" ]; then
    printf '%s\n' "$FILES_JSON"
fi
printf '  ],\n'
printf '  "tags": "%s",\n' "$(echo "$TAGS" | xargs)"
printf '  "languages": "%s"\n' "$(echo "$LANGUAGES" | xargs)"
printf '}\n'
