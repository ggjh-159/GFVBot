#!/usr/bin/env bash
# setup-centos9.sh — dependency installer for CentOS Stream 9 (gfvbot env backend).
#
# CentOS 9 specifics handled here:
#   * EPEL + CRB repos are enabled before build-tools: ninja-build and ccache
#     live there, not in BaseOS/AppStream (mirroring Velox's own centos9
#     setup). Enabling is idempotent and failure-tolerered; if it fails the
#     package install reports the failure instead.
#   * RHEL9 package names: libzstd-devel / curl-devel (openEuler calls them
#     zstd-devel / libcurl-devel).
#
# Probes everything itself (no jq / no env.json needed), shows an interactive
# tick-list, installs via dnf, then re-execs the environment check so
# .gfvbot/env.json reflects the new state. flink (Apache tarball under /opt)
# and nexmark (built from source) are optional entries shared with the other
# OS scripts via lib/common.sh.
#
# Invoked automatically by env.sh when the OS matches; can also be run
# directly:  bash installer/env-init/setup-centos9.sh [--target <dir>]

set -u

ROOT="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../.." && pwd)"
# shellcheck source=lib/common.sh
. "$ROOT/installer/lib/common.sh"

TARGET="$PWD"
while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    *) die "$(t err_unknown_arg "$1")" ;;
  esac
done

# --- probe what is missing (self-contained, mirrors env.sh's scan) -----------
MISSING=()
for dep in jq git cmake gcc g++ mvn; do
  command -v "$dep" >/dev/null 2>&1 || MISSING+=("$dep")
done
if ! find_jdk 8 && ! find_jdk 17; then
  MISSING+=("jdk-17")
fi
[ -n "$(build_tool_missing)" ] && MISSING+=("build-tools")
[ -n "$(cpp_dep_missing)" ] && MISSING+=("cpp-deps")
stack_flink_root >/dev/null 2>&1 || MISSING+=("flink")
[ -z "$(stack_nexmark_jar)" ] && MISSING+=("nexmark")
# source-deps (Velox's source-built C++ libs): only offered when the velox
# checkout exists — the library list and the install functions come from it.
if find_velox_checkout_dir "$TARGET" >/dev/null 2>&1; then
  [ -n "$(bash "$ROOT/installer/env-init/source-deps.sh" --target "$TARGET" --probe-only)" ] && MISSING+=("source-deps")
fi
if [ "${#MISSING[@]}" -eq 0 ]; then
  echo
  ok "$(t env_all_present)"
  exec bash "$ROOT/installer/env.sh" --target "$TARGET"
fi

# --- interactive install ------------------------------------------------------
echo
if ! { [ -t 0 ] && [ -t 1 ]; }; then
  warn "$(t env_noninteractive "$0")"
  exit 0
fi

command -v dnf >/dev/null 2>&1 || { warn "$(t env_no_pm)"; exit 0; }

ui_pick env_pick_title ui_pick_hint "${MISSING[@]}" || { echo; warn "$(t env_install_cancelled)"; exit 0; }
if [ "${#PICKED[@]}" -eq 0 ]; then
  echo
  warn "$(t env_install_none)"
  exit 0
fi

pkg_for() {  # <dep> → CentOS 9 package name
  case "$1" in
    g++)    echo gcc-c++ ;;
    mvn)    echo maven ;;
    jdk-17) echo java-17-openjdk-devel ;;
    build-tools)
      echo "ninja-build ccache autoconf automake libtool flex bison python3 patchelf" ;;
    cpp-deps)
      echo "libevent-devel openssl-devel re2-devel libzstd-devel lz4-devel \
double-conversion-devel libdwarf-devel elfutils-libelf-devel curl-devel \
libicu-devel libsodium-devel zlib-devel librdkafka-devel" ;;
    *)      echo "$1" ;;
  esac
}

FAIL=0
for dep in "${PICKED[@]}"; do
  case "$dep" in
    flink)   install_flink || { err "$(t env_install_failed flink)"; FAIL=1; } ;;
    nexmark) install_nexmark || { err "$(t env_install_failed nexmark)"; FAIL=1; } ;;
    source-deps)
      bash "$ROOT/installer/env-init/source-deps.sh" --target "$TARGET" \
        || { err "$(t env_install_failed source-deps)"; FAIL=1; } ;;
    build-tools)
      # ninja/ccache need EPEL + CRB first; failure here surfaces via the
      # package install that follows, so enabling itself stays best-effort
      echo "  $(t env_enable_epel_crb)"
      dnf install -y -q epel-release dnf-plugins-core >/dev/null 2>&1 || true
      dnf config-manager --set-enabled crb >/dev/null 2>&1 || true
      pkg=$(pkg_for "$dep")
      echo "  $(t env_installing "$dep ($pkg)")"
      # shellcheck disable=SC2086
      dnf install -y $pkg || { err "$(t env_install_failed "$dep")"; FAIL=1; } ;;
    *)
      pkg=$(pkg_for "$dep")
      echo "  $(t env_installing "$dep ($pkg)")"
      # shellcheck disable=SC2086
      dnf install -y $pkg || { err "$(t env_install_failed "$dep")"; FAIL=1; } ;;
  esac
done
if [ "$FAIL" -eq 1 ]; then
  exit 1   # a failed package would leave the rescan lying; fix it, rerun
fi

# re-check so the archive reflects the new state
echo
step "$(t env_rescan)"
exec bash "$ROOT/installer/env.sh" --target "$TARGET"
