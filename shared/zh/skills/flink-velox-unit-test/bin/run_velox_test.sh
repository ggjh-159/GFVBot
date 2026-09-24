#!/bin/bash
# run_velox_test.sh — build and run velox C++ unit tests via cmake.
#
# Repo paths come from the GFV workspace env archive (.gfvbot/env.json,
# produced by `gfvbot env` and extended by `gfvbot clone`); no hand-maintained
# config file is read. The script walks upward from its own location to find
# the archive.
#
# Usage: bash run_velox_test.sh [test_target|all] [gtest_filter]
#
# Examples:
#   bash run_velox_test.sh velox_stateful_udf_test
#   bash run_velox_test.sh velox_nexmark_connector_test NexmarkConnectorTest.testRows
#
# Supports incremental builds: re-running only recompiles changed files.
# Prerequisites: a velox4j build must exist under repos/velox4j/src/main/cpp/build/
# to reuse downloaded dependencies (rocksdb, grpc, re2, googletest, fmt, etc.).

set -e

# Locate .gfvbot/env.json by walking upward from this script.
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SEARCH_DIR="$SCRIPT_DIR"
ENV_JSON=""
while [ "$SEARCH_DIR" != "/" ]; do
    if [ -f "$SEARCH_DIR/.gfvbot/env.json" ]; then
        ENV_JSON="$SEARCH_DIR/.gfvbot/env.json"
        break
    fi
    SEARCH_DIR="$(dirname "$SEARCH_DIR")"
done
if [ -z "$ENV_JSON" ]; then
    echo "Error: .gfvbot/env.json not found in any parent directory." >&2
    echo "Hint: run 'gfvbot env' in the workspace root first." >&2
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required to read $ENV_JSON but not installed." >&2
    exit 1
fi

VELOX_DIR=$(jq -r '.repos["velox"].path // empty' "$ENV_JSON")
V4J_ROOT=$(jq -r '.repos["velox4j"].path // empty' "$ENV_JSON")
if [ -z "$VELOX_DIR" ] || [ "$VELOX_DIR" = "null" ]; then
    echo "Error: repos/velox path missing — run 'gfvbot clone' (archive: $ENV_JSON)" >&2
    exit 1
fi
if [ -z "$V4J_ROOT" ] || [ "$V4J_ROOT" = "null" ]; then
    echo "Error: repos/velox4j path missing — run 'gfvbot clone' (archive: $ENV_JSON)" >&2
    exit 1
fi

BUILD_DIR=$VELOX_DIR/_build/debug
V4J_DEPS=$V4J_ROOT/src/main/cpp/build/_deps

TEST_TARGET="${1:-velox_stateful_udf_test}"
GTEST_FILTER="$2"
ENABLE_SPARK_FUNCTIONS="${ENABLE_SPARK_FUNCTIONS:-OFF}"

# Targets to build/run when "all" is specified.
ALL_TARGETS=(
  velox_nexmark_generator_test
  velox_nexmark_utils_test
)

# Copy pre-downloaded deps from velox4j build to avoid re-downloading.
mkdir -p "$BUILD_DIR/_deps"
for dep in rocksdb grpc re2 googletest fmt xsimd \
           simdjson double-conversion glog gflags folly \
           libevent lzo snappy zlib zstd lz4 \
           protobuf cares boost cpr curl; do
  src="$V4J_DEPS/${dep}-src"
  dst="$BUILD_DIR/_deps/${dep}-src"
  if [ -d "$src" ] && [ ! -e "$dst" ]; then
    cp -r "$src" "$dst"
  fi
done

# Build FETCHCONTENT_SOURCE_DIR_* flags from pre-copied deps.
# This tells cmake to use local source dirs instead of downloading.
FETCH_FLAGS=""
for dep_src in "$BUILD_DIR"/_deps/*-src; do
  [ -d "$dep_src" ] || continue
  dep_name=$(basename "$dep_src" -src)
  upper_name=$(echo "$dep_name" | tr '[:lower:]-' '[:upper:]_')
  FETCH_FLAGS="$FETCH_FLAGS -DFETCHCONTENT_SOURCE_DIR_${upper_name}=${dep_src}"
done

# Configure cmake with testing enabled.
cmake -S "$VELOX_DIR" -B "$BUILD_DIR" \
  -DVELOX_MONO_LIBRARY=ON \
  -DVELOX_BUILD_TESTING=ON \
  -DVELOX_ENABLE_PARQUET=OFF \
  -DVELOX_ENABLE_PULSAR_CONNECTOR=OFF \
  -DVELOX_ENABLE_HIVE_CONNECTOR=ON \
  -DVELOX_ENABLE_PRESTO_FUNCTIONS=ON \
  -DVELOX_ENABLE_EXPRESSION=ON \
  -DVELOX_ENABLE_EXEC=ON \
  -DVELOX_ENABLE_SPARK_FUNCTIONS=$ENABLE_SPARK_FUNCTIONS \
  -DCMAKE_BUILD_TYPE=Debug \
  -DWITH_TESTS=OFF \
  -DWITH_BENCHMARK_TOOLS=OFF \
  -DWITH_TOOLS=OFF \
  -DDuckDB_SOURCE=BUNDLED \
  -DBUILD_JEMALLOC_EXTENSION=OFF \
  $FETCH_FLAGS

# Build and run.
cd "$BUILD_DIR"

if [ "$TEST_TARGET" = "all" ]; then
  for target in "${ALL_TARGETS[@]}"; do
    cmake --build . --target "$target" -j "$(nproc)"
  done
  for target in "${ALL_TARGETS[@]}"; do
    echo "=== Running $target ==="
    ctest -R "$target" -V
  done
else
  cmake --build . --target "$TEST_TARGET" -j "$(nproc)"
  if [ -n "$GTEST_FILTER" ]; then
    ctest -R "$TEST_TARGET" -V --output-on-failure -- "$GTEST_FILTER"
  else
    ctest -R "$TEST_TARGET" -V
  fi
fi
