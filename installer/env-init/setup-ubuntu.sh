#!/usr/bin/env bash
# setup-ubuntu.sh — dependency installer for Ubuntu (gfvbot env backend);
# also serves Debian (os.id=debian — same package family).
#
# Ubuntu specifics handled here:
#   * Debian-style -dev package names (libssl-dev / zlib1g-dev /
#     libcurl4-openssl-dev ...) and openjdk-* JDK packages.
#   * curl is probed alongside the tools: the base image ships without it,
#     and the flink tarball download needs it.
#   * apt-get update runs (best-effort) before installing: a fresh
#     container carries empty package lists and every install would fail.
#
# flink (Apache tarball under /opt) and nexmark (built from source) are
# shared with the other OS scripts via lib/common.sh.
#
# Probes everything itself (no jq / no env.json needed), shows an interactive
# tick-list, installs via apt-get, then re-execs the environment check so
# .gfvbot/env.json reflects the new state.
#
# Invoked automatically by env.sh when the OS matches; can also be run
# directly:  bash installer/env-init/setup-ubuntu.sh [--target <dir>]

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
for dep in jq curl git cmake gcc g++ mvn; do
  command -v "$dep" >/dev/null 2>&1 || MISSING+=("$dep")
done
if ! find_jdk 8 && ! find_jdk 17; then
  MISSING+=("jdk-17")
fi
[ -n "$(build_tool_missing)" ] && MISSING+=("build-tools")
[ -n "$(cpp_dep_missing)" ] && MISSING+=("cpp-deps")
stack_flink_root >/dev/null 2>&1 || MISSING+=("flink")
[ -z "$(stack_nexmark_jar)" ] && MISSING+=("nexmark")
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

command -v apt-get >/dev/null 2>&1 || { warn "$(t env_no_pm)"; exit 0; }

ui_pick env_pick_title ui_pick_hint "${MISSING[@]}" || { echo; warn "$(t env_install_cancelled)"; exit 0; }
if [ "${#PICKED[@]}" -eq 0 ]; then
  echo
  warn "$(t env_install_none)"
  exit 0
fi

echo "  $(t env_apt_update)"
apt-get update -qq >/dev/null 2>&1 || true

pkg_for() {  # <dep> → Ubuntu package name
  case "$1" in
    g++)    echo g++ ;;
    mvn)    echo maven ;;
    jdk-17) echo openjdk-17-jdk ;;
    build-tools)
      echo "ninja-build ccache autoconf automake libtool libtool-bin flex bison python3" ;;
    cpp-deps)
      echo "libevent-dev libssl-dev libre2-dev libzstd-dev liblz4-dev \
libdouble-conversion-dev libdwarf-dev libelf-dev libcurl4-openssl-dev \
libicu-dev libsodium-dev zlib1g-dev" ;;
    *)      echo "$1" ;;
  esac
}

FAIL=0
for dep in "${PICKED[@]}"; do
  case "$dep" in
    flink)   install_flink || { err "$(t env_install_failed flink)"; FAIL=1; } ;;
    nexmark) install_nexmark || { err "$(t env_install_failed nexmark)"; FAIL=1; } ;;
    *)
      pkg=$(pkg_for "$dep")
      echo "  $(t env_installing "$dep ($pkg)")"
      # DEBIAN_FRONTEND: distro prompts (tzdata region etc.) must not pierce
      # our tick-list interaction — the tool's own UI is the only dialog
      # shellcheck disable=SC2086
      DEBIAN_FRONTEND=noninteractive apt-get install -y $pkg || { err "$(t env_install_failed "$dep")"; FAIL=1; } ;;
  esac
done
if [ "$FAIL" -eq 1 ]; then
  exit 1   # a failed package would leave the rescan lying; fix it, rerun
fi

# re-check so the archive reflects the new state
echo
step "$(t env_rescan)"
exec bash "$ROOT/installer/env.sh" --target "$TARGET"
