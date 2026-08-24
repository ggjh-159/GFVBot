#!/usr/bin/env bash
# setup-centos7.sh — dependency installer for CentOS 7 (gfvbot env backend).
#
# CentOS 7 specifics handled here:
#   * EOL distro: upstream yum mirrors are gone, so dead repos are detected
#     and (after asking) rewritten to an archive mirror — original repo file
#     kept as *.gfvbot.bak.
#   * No OpenJDK 17 in the archives: a Temurin 17 tarball is downloaded
#     (Adoptium API, Tsinghua mirror as fallback) and unpacked to
#     /usr/lib/jvm/java-17-adoptium, which env.sh's probe picks up.
#
# Probes everything itself (no jq / no env.json needed), shows an interactive
# tick-list, installs, then re-execs the environment check so
# .gfvbot/env.json reflects the new state.
#
# Invoked automatically by env.sh when the OS matches; can also be run
# directly:  bash installer/env-init/setup-centos7.sh [--target <dir>]

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

find_jdk() {  # <8|17> → jdk dir (has bin/javac) or nothing
  local d
  case "$1" in
    8)  for d in /usr/lib/jvm/java-1.8.0-openjdk-* /usr/lib/jvm/java-8-openjdk-*; do
          [ -x "$d/bin/javac" ] && { printf '%s' "$d"; return 0; }
        done ;;
    17) for d in /usr/lib/jvm/java-17-*; do
          [ -x "$d/bin/javac" ] && { printf '%s' "$d"; return 0; }
        done ;;
  esac
  return 1
}

install_jdk17_tarball() {
  local mfile arch=$(uname -m) dir
  case "$arch" in
    aarch64) arch=aarch64 ;;
    x86_64)  arch=x64 ;;
    *) err "$(t env_jdk17_failed)"; return 1 ;;
  esac
  # each source gets ONE attempt with a hard cap: a slow mirror must not
  # stall the whole install for the better part of an hour. Tsinghua first
  # (fast in CN), Adoptium API as the fallback.
  local tuna="https://mirrors.tuna.tsinghua.edu.cn/Adoptium/17/jdk/$arch/linux"
  local api="https://api.adoptium.net/v3/binary/latest/17/ga/linux/$arch/jdk/hotspot/normal/eclipse"
  local tmp; tmp=$(mktemp -d)
  echo "  $(t env_dl_jdk17 "$tuna/")"
  mfile=$(curl -fsSL --max-time 30 "$tuna/" 2>/dev/null \
    | grep -oE "OpenJDK17U-jdk_${arch}_linux_hotspot_[0-9._]+\.tar\.gz" | sort -V | tail -1)
  if [ -z "$mfile" ] \
    || ! curl -fsSL --max-time 900 -o "$tmp/jdk17.tar.gz" "$tuna/$mfile"; then
    echo "  $(t env_dl_jdk17 "$api")"
    if ! curl -fsSL --max-time 900 -o "$tmp/jdk17.tar.gz" "$api"; then
      rm -rf "$tmp"
      err "$(t env_jdk17_failed)"
      return 1
    fi
  fi
  mkdir -p /usr/lib/jvm
  rm -rf /usr/lib/jvm/java-17-adoptium
  tar -xzf "$tmp/jdk17.tar.gz" -C /usr/lib/jvm
  dir=$(ls -dt /usr/lib/jvm/jdk-17* 2>/dev/null | head -1)
  if [ -z "$dir" ]; then
    rm -rf "$tmp"
    err "$(t env_jdk17_failed)"
    return 1
  fi
  mv "$dir" /usr/lib/jvm/java-17-adoptium
  rm -rf "$tmp"
  ok "$(t env_jdk17_done /usr/lib/jvm/java-17-adoptium)"
}

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

command -v yum >/dev/null 2>&1 || { warn "$(t env_no_pm)"; exit 0; }

# dead repos (EOL) must be repaired before any yum call can succeed
ensure_centos_repos || exit 0

ui_pick env_pick_title ui_pick_hint "${MISSING[@]}" || { echo; warn "$(t env_install_cancelled)"; exit 0; }
if [ "${#PICKED[@]}" -eq 0 ]; then
  echo
  warn "$(t env_install_none)"
  exit 0
fi

pkg_for() {  # <dep> → CentOS 7 package name (jdk-17 is not a yum package);
             # groups expand to the packages the vault archive still carries —
             # ninja/ccache (dead EPEL) and zstd/double-conversion/sodium
             # (never in vault) stay uninstalled and keep showing as missing;
             # re2-devel exists in the x86_64 archive only, so yum skips it
             # silently on aarch64 and the probe reports it missing
  case "$1" in
    g++)    echo gcc-c++ ;;
    mvn)    echo maven ;;
    build-tools)
      echo "autoconf automake libtool flex bison python3" ;;
    cpp-deps)
      echo "libevent-devel openssl-devel re2-devel lz4-devel libdwarf-devel \
elfutils-libelf-devel libcurl-devel libicu-devel zlib-devel" ;;
    *)      echo "$1" ;;
  esac
}

FAIL=0
for dep in "${PICKED[@]}"; do
  case "$dep" in
    jdk-17)
      install_jdk17_tarball || FAIL=1 ;;
    jq)
      # jq ships in EPEL which is gone with EOL; static binary instead
      install_jq_static || { err "$(t env_install_failed jq)"; FAIL=1; } ;;
    *)
      pkg=$(pkg_for "$dep")
      echo "  $(t env_installing "$dep ($pkg)")"
      # shellcheck disable=SC2086
      yum install -y $pkg || { err "$(t env_install_failed "$dep")"; FAIL=1; } ;;
  esac
done
if [ "$FAIL" -eq 1 ]; then
  exit 1   # a failed package would leave the rescan lying; fix it, rerun
fi

# re-check so the archive reflects the new state
echo
step "$(t env_rescan)"
exec bash "$ROOT/installer/env.sh" --target "$TARGET"
