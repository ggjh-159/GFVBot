#!/usr/bin/env bash
# source-deps.sh — install Velox's source-built C++ libraries into /usr/local
# (env-init backend; tick-list entry "source-deps").
#
# The package-manager cpp-deps entry only covers what dnf/apt ships. On the
# GFV build path Velox resolves the rest — boost, the folly chain, protobuf
# (protoc must match the pinned headers), arrow, ... — from /usr/local, and
# the installs are driven by Velox's own official setup script so every
# version stays pinned by the workspace checkout.
#
# The library list is not maintained here: it is parsed from the install
# function call sequence inside the velox checkout's setup script, minus the
# package-manager and conda entries. Whatever branch the checkout is on, that
# is the list. Libraries already detectable under /usr/local are skipped, so
# reruns only build what is missing; a missing probe override at worst
# reinstalls a library, it never drops one.
#
# Needs repos/velox from `gfvbot clone`; when it is absent the caller is
# pointed there. Can also be run directly:
#   bash installer/env-init/source-deps.sh [--target <dir>] [--probe-only] [<library>...]

set -uo pipefail

ROOT="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../.." && pwd)"
# shellcheck source=lib/common.sh
. "$ROOT/installer/lib/common.sh"

TARGET="$PWD"
PROBE_ONLY=""
FILTER=()
while [ $# -gt 0 ]; do
  case "$1" in
    --target)     [ $# -ge 2 ] || die "$(t err_needs_value "$1")"
                  TARGET="$2"; shift 2 ;;
    --probe-only) PROBE_ONLY=1; shift ;;
    *)            FILTER+=("$1"); shift ;;
  esac
done

# Locate the velox checkout: standard workspace layout first (laid down by
# gfvbot clone), the env.json record second — see find_velox_checkout_dir.
VELOX_PATH="$(find_velox_checkout_dir "$TARGET")" || {
  [ -n "$PROBE_ONLY" ] && exit 0
  die "$(t sd_no_velox)"
}

# Pick the velox setup script for this OS. The install_* functions themselves
# are OS-agnostic (wget + cmake); only the skipped package-manager entry
# differs per script.
os_velox_setup() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
  fi
  case "${ID:-}:${VERSION_ID:-}" in
    ubuntu:*|debian:*) echo "setup-ubuntu.sh" ;;
    centos:7|rhel:7)   echo "" ;;  # vault repos; not supported
    *)                 echo "setup-centos9.sh" ;;
  esac
}
VELOX_SETUP_NAME="$(os_velox_setup)"
[ -n "$VELOX_SETUP_NAME" ] || die "$(t sd_os_unsupported)"
VELOX_SETUP="$VELOX_PATH/scripts/$VELOX_SETUP_NAME"

# The authoritative list: the call sequence inside install_velox_deps in the
# velox setup script, minus the package-manager and conda entries (those are
# env-init's business). Order is preserved — later libraries build against
# earlier ones.
velox_source_libs() {
  sed -n '/^function install_velox_deps {/,/^}/p' "$VELOX_SETUP" \
    | sed -n 's/^[[:space:]]*run_and_time[[:space:]]\+install_\(.\+\)[[:space:]]*$/\1/p' \
    | grep -v '_from_dnf$' | grep -v '_from_apt$' | grep -v '^conda$'
}
mapfile -t LIBS < <(velox_source_libs)
[ "${#LIBS[@]}" -gt 0 ] || die "$(t sd_parse_failed "$VELOX_SETUP")"

# A few installs land under a name the generic probe cannot derive from the
# library name; missing entries here only cause a redundant rebuild.
declare -A PROBE_OVERRIDE=( [protobuf]=protoc )

# Installed = any credible /usr/local artifact for the library name: a cmake
# config dir (name, Capitalized, UPPER), an include dir, a matching header
# (with the lib* C-library prefix), or an override binary.
lib_present() {  # <lib>
  local n="$1" c o
  for c in "$n" "${n^}" "${n^^}"; do
    [ -d "/usr/local/lib/cmake/$c" ] && return 0
    [ -d "/usr/local/lib64/cmake/$c" ] && return 0
  done
  [ -d "/usr/local/include/$n" ] && return 0
  [ -f "/usr/local/include/$n.h" ] && return 0
  [ -f "/usr/local/include/lib$n.h" ] && return 0
  o="${PROBE_OVERRIDE[$n]:-}"
  [ -n "$o" ] && [ -x "/usr/local/bin/$o" ] && return 0
  return 1
}

if [ -n "$PROBE_ONLY" ]; then
  for lib in "${LIBS[@]}"; do
    if [ "${#FILTER[@]}" -gt 0 ]; then
      keep=""
      for f in "${FILTER[@]}"; do [ "$f" = "$lib" ] && keep=1; done
      [ -n "$keep" ] || continue
    fi
    lib_present "$lib" || echo "$lib"
  done
  exit 0
fi

step "$(t sd_title)"
TODO=()
for lib in "${LIBS[@]}"; do
  if [ "${#FILTER[@]}" -gt 0 ]; then
    keep=""
    for f in "${FILTER[@]}"; do [ "$f" = "$lib" ] && keep=1; done
    [ -n "$keep" ] || continue
  fi
  if lib_present "$lib"; then
    ok "$(t sd_skip "$lib")"
  else
    TODO+=("$lib")
  fi
done
if [ "${#TODO[@]}" -eq 0 ]; then
  echo
  ok "$(t sd_all_present)"
  exit 0
fi

# Drive Velox's own install functions in a subshell so the official script's
# set -e/-x and exports stay contained; the sourced script's main block is
# guarded by "(return) && return" and never runs.
export INSTALL_PREFIX=/usr/local
export DEPENDENCY_DIR="${GFVBOT_SOURCE_DEPS_DIR:-/tmp/gfvbot-source-deps}"
export BUILD_THREADS="${BUILD_THREADS:-128}"
export PROMPT_ALWAYS_RESPOND=n   # never ask to wipe DEPENDENCY_DIR
# A download cut mid-stream leaves a dependency dir holding only a partial
# tarball; with prompts silenced velox's wget_and_untar would then treat the
# dir as populated and skip the fetch forever. Wipe such dirs before driving
# the install — a dir with any build entry file is a real pre-placed tree and
# is left alone.
stale_dep_dir() {  # <lib> → 0 when the dir exists but holds no real sources
  local d="$DEPENDENCY_DIR/$1"
  [ -d "$d" ] || return 1
  if [ -f "$d/CMakeLists.txt" ] || [ -f "$d/configure" ] || [ -f "$d/Makefile" ] \
    || [ -f "$d/bootstrap.sh" ] || [ -f "$d/setup.py" ]; then
    return 1   # a build entry file means a real (pre-placed) tree
  fi
  return 0
}
FAIL=0
for lib in "${TODO[@]}"; do
  if stale_dep_dir "$lib"; then
    echo "  $(t sd_stale_wipe "$lib")"
    rm -rf "${DEPENDENCY_DIR:?}/$lib"
  fi
  echo "  $(t sd_building "$lib")"
  if ! (
    set -e
    # shellcheck disable=SC1090
    source "$VELOX_SETUP" > /dev/null   # trace noise to the bit bucket
    set +x                              # keep -e for the official functions
    "install_$lib"
  ); then
    err "$(t sd_failed "$lib")"
    FAIL=1
    break   # later libraries build against earlier ones; stop at the gap
  fi
done
[ "$FAIL" -eq 0 ] && echo && ok "$(t sd_done)"
exit "$FAIL"
