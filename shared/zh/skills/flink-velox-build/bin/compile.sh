#!/bin/bash
# compile.sh — build velox4j (native .so included) and gluten-flink, then
# deploy the jars into the local Flink installation.
#
# All paths come from the GFV workspace env archive (.gfvbot/env.json,
# produced by `gfvbot env` and extended by `gfvbot clone`); no hand-maintained
# config file is read. The script walks upward from its own location to find
# the archive, so it works both from the installed skill directory and from a
# copy placed anywhere under the workspace root.
#
# Usage: bash compile.sh [velox4j|gluten|all] [--with-tests|--with-ut]

set -euo pipefail

# Locate .gfvbot/env.json by walking upward from this script.
SELF="${BASH_SOURCE[0]}"
while [ -L "$SELF" ]; do
    DIR="$(cd "$(dirname "$SELF")" && pwd)"
    SELF="$(readlink "$SELF")"
    [[ "$SELF" != /* ]] && SELF="$DIR/$SELF"
done
SEARCH_DIR="$(cd "$(dirname "$SELF")" && pwd)"
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

# Extract the paths the build needs. Each field must be present and ok,
# otherwise point at the gfvbot command that produces it.
need_json_field() {  # <jq-filter> <missing-message>
    local v
    v=$(jq -r "$1" "$ENV_JSON")
    if [ -z "$v" ] || [ "$v" = "null" ]; then
        echo "Error: $2 (archive: $ENV_JSON)" >&2
        exit 1
    fi
    printf '%s' "$v"
}

VELOX_PATH=$(need_json_field '.repos["velox"].path // empty' \
    "repos/velox path missing — run 'gfvbot clone'")
VELOX4J_PATH=$(need_json_field '.repos["velox4j"].path // empty' \
    "repos/velox4j path missing — run 'gfvbot clone'")
GLUTEN_FLINK_PATH=$(need_json_field '.repos["gluten"].path // empty' \
    "repos/gluten path missing — run 'gfvbot clone'")
GLUTEN_FLINK_PATH="$GLUTEN_FLINK_PATH/gluten-flink"
FLINK_HOME=$(need_json_field '.stack.flink.path // empty' \
    "flink installation missing — run 'gfvbot env'")
JAVA_HOME=$(need_json_field \
    '.env.JAVA_HOME.value // .jdks["17"].path // .jdks["8"].path // empty' \
    "no usable JDK recorded — run 'gfvbot env'")
# Optional: nexmark jar recorded as a full path; absence only skips the
# local-Maven install step.
NEXMARK_JAR=$(jq -r '.stack.nexmark.path // empty' "$ENV_JSON")

# Third-party jars the GFV jars need at runtime beyond flink's own lib/
# (velox4j JNI uses guava/arrow, gluten uses jackson/flatbuffers). Resolved
# from the local Maven repository the build above just populated; keep the
# GA:version list in sync with what velox4j/gluten-flink resolve.
RUNTIME_DEPS=(
    "com.google.guava:guava:33.4.0-jre"
    "com.google.guava:failureaccess:1.0.2"
    "org.apache.arrow:arrow-c-data:18.1.0"
    "org.apache.arrow:arrow-format:18.1.0"
    "org.apache.arrow:arrow-memory-core:18.1.0"
    "org.apache.arrow:arrow-memory-unsafe:18.1.0"
    "org.apache.arrow:arrow-vector:18.1.0"
    "commons-io:commons-io:2.18.0"
    "com.google.flatbuffers:flatbuffers-java:24.3.25"
    "com.fasterxml.jackson.core:jackson-annotations:2.18.0"
    "com.fasterxml.jackson.core:jackson-core:2.18.0"
    "com.fasterxml.jackson.core:jackson-databind:2.18.0"
    "com.fasterxml.jackson.datatype:jackson-datatype-jdk8:2.18.0"
    "com.fasterxml.jackson.datatype:jackson-datatype-jsr310:2.18.0"
)

deploy_runtime_deps() {
    local dep g a v path missing=()
    for dep in "${RUNTIME_DEPS[@]}"; do
        g=${dep%%:*}
        a=${dep#*:}; a=${a%%:*}
        v=${dep##*:}
        path="$HOME/.m2/repository/${g//.///}/$a/$v/$a-$v.jar"
        if [ -f "$path" ]; then
            \cp "$path" "$FLINK_HOME/lib/"
        else
            missing+=("$dep")
        fi
    done
    if [ "${#missing[@]}" -gt 0 ]; then
        echo "Warning: runtime deps not in local Maven repo, flink may fail to load GFV jars:" >&2
        printf '  %s\n' "${missing[@]}" >&2
    fi
}

# Pin the cluster to the build JDK: gluten-flink jars shade Java-17 bytecode
# (including shadowed Flink runtime classes), so a cluster daemon on an older
# JDK dies on UnsupportedClassVersionError. Flink's config.sh reads the java
# home from flink-conf.yaml's env.java.home key (conf/flink-env.sh is not
# sourced anymore). Fill-only: an existing value belongs to the user's setup
# and is left untouched (warned about when it differs from the build JDK).
pin_flink_jdk() {
    local conf="$FLINK_HOME/conf/flink-conf.yaml"
    mkdir -p "$FLINK_HOME/conf"
    touch "$conf"
    local cur
    cur=$(grep -E '^env\.java\.home:' "$conf" | head -1 \
          | sed 's/^env\.java\.home:[[:space:]]*//; s/[[:space:]]*$//')
    if [ -z "$cur" ]; then
        echo "env.java.home: $JAVA_HOME" >> "$conf"
    elif [ "$cur" != "$JAVA_HOME" ]; then
        echo "  WARNING: $conf pins env.java.home to $cur but this build used $JAVA_HOME; leaving the configured value untouched (gluten jars need JDK 17 at runtime)" >&2
    fi
}

compile_velox4j() {
    echo "Compiling velox4j..."
    export JAVA_HOME="$JAVA_HOME"
    export PATH="$JAVA_HOME/bin:$PATH"
    # Build the native part against the workspace velox checkout instead of
    # letting CPM fetch a pinned commit: local edits to repos/velox must end
    # up in the produced .so, and the fetch would be a large, failure-prone
    # download. VELOX4J_BUILD_JOBS bounds compile parallelism (nproc can far
    # exceed what the memory of the machine sustains for C++ units).
    export VELOX4J_VELOX_SOURCE_DIR="$VELOX_PATH"
    export VELOX4J_BUILD_JOBS="${VELOX4J_BUILD_JOBS:-128}"
    cd "$VELOX4J_PATH"
    local MVN_COMMON_ARGS=(-Dgpg.skip -Dgpg.skip=true -Dmaven.javadoc.skip=true)
    if [ "${RUN_TESTS}" = "true" ]; then
        mvn clean install "${MVN_COMMON_ARGS[@]}"
    else
        mvn clean install -DskipTests "${MVN_COMMON_ARGS[@]}"
    fi
    echo "Deploying velox4j jar to ${FLINK_HOME}/lib/..."
    \cp target/velox4j-0.1.0-SNAPSHOT.jar "${FLINK_HOME}/lib/"
    deploy_runtime_deps
    pin_flink_jdk
    echo "velox4j compilation completed."
}

install_nexmark() {
    if [ -z "$NEXMARK_JAR" ] || [ ! -f "$NEXMARK_JAR" ]; then
        echo "Warning: nexmark-flink jar not found (looked at: ${NEXMARK_JAR:-<unrecorded>}), skipping installation."
        return 0
    fi
    echo "Installing nexmark-flink to local Maven repository..."
    export JAVA_HOME="$JAVA_HOME"
    export PATH="$JAVA_HOME/bin:$PATH"
    # Scratch space lives inside the project (next to the env archive),
    # never in /tmp — users only look inside the project directory.
    local NEXMARK_TMP
    NEXMARK_TMP="$(dirname "$ENV_JSON")/.gfvbot/tmp/nexmark-pom"
    rm -rf "$NEXMARK_TMP"
    mkdir -p "$NEXMARK_TMP"
    cd "$NEXMARK_TMP"
    jar -xf "$NEXMARK_JAR" META-INF/maven/com.github.nexmark/nexmark-flink/pom.xml
    mvn install:install-file -Dfile="$NEXMARK_JAR" -DpomFile=META-INF/maven/com.github.nexmark/nexmark-flink/pom.xml
    rm -rf "$NEXMARK_TMP"
}

compile_gluten() {
    echo "Compiling gluten-flink..."
    export JAVA_HOME="$JAVA_HOME"
    export PATH="$JAVA_HOME/bin:$PATH"
    install_nexmark
    cd "$GLUTEN_FLINK_PATH"
    local MVN_COMMON_ARGS=(-Dgpg.skip -Dgpg.skip=true -Dmaven.javadoc.skip=true)
    if [ "${RUN_TESTS}" = "true" ]; then
        mvn clean install "${MVN_COMMON_ARGS[@]}"
    else
        mvn clean install -DskipTests "${MVN_COMMON_ARGS[@]}" -pl planner,loader,runtime
    fi
    echo "Deploying gluten-flink jars to ${FLINK_HOME}/lib/..."
    \cp planner/target/gluten-flink-planner-1.8.0-SNAPSHOT.jar "${FLINK_HOME}/lib/"
    \cp runtime/target/gluten-flink-runtime-1.8.0-SNAPSHOT.jar "${FLINK_HOME}/lib/"
    \cp loader/target/gluten-flink-loader-1.8.0-SNAPSHOT.jar "${FLINK_HOME}/lib/"
    deploy_runtime_deps
    pin_flink_jdk
    echo "gluten-flink compilation completed."
}

compile_all() {
    compile_velox4j
    compile_gluten
}

RUN_TESTS="false"
for arg in "$@"; do
    if [ "$arg" = "--with-tests" ] || [ "$arg" = "--with-ut" ]; then
        RUN_TESTS="true"
    fi
done

case "${1:-all}" in
    velox4j)
        compile_velox4j
        ;;
    gluten)
        compile_gluten
        ;;
    all)
        compile_all
        ;;
    *)
        echo "Usage: $0 [velox4j|gluten|all] [--with-tests|--with-ut]" >&2
        exit 1
        ;;
esac
