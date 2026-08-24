#!/usr/bin/env bash
# env.sh — GFVBot environment check engine (gfvbot env backend).
#
# Scans build dependencies (git / cmake / gcc / g++ / mvn / OpenJDK 8|17 /
# JAVA_HOME / build tools / Velox's dnf-level C++ libraries), machine facts
# (os / kernel / arch / cpu / memory / disk), the flink/nexmark stack, and
# locally available AI agent CLIs; archives everything to
# <target>/.gfvbot/env.json. jq is this checker's own prerequisite and gets
# auto-installed up front. When dependencies are missing, the run hands over
# to the OS-specific installer under installer/env-init/ (which installs,
# then re-execs this script). Re-running rescans everything, so
# appearing/disappearing tools and agents are reflected in the archive.

set -u

ROOT="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/.." && pwd)"
# shellcheck source=lib/common.sh
. "$ROOT/installer/lib/common.sh"

TARGET="$PWD"
while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    *) die "$(t err_unknown_arg "$1")" ;;
  esac
done

# jq is this checker's own prerequisite: without it the archive cannot be
# produced at all, so install it right away (no tick-list, works headless too).
ensure_jq() {
  command -v jq >/dev/null 2>&1 && return 0
  warn "$(t env_missing jq)"
  ensure_centos_repos || die "$(t env_jq_manual)"   # CentOS 7 EOL repos would doom the jq install
  local pm
  pm=$(detect_pm)
  if [ -n "$pm" ]; then
    echo "  $(t env_installing_jq)"
    case "$pm" in
      dnf)     dnf install -y jq ;;
      yum)     yum install -y jq ;;
      apt-get) apt-get install -y jq ;;
    esac
    command -v jq >/dev/null 2>&1 && return 0
  fi
  # fallback: static binary — e.g. CentOS 7 carries no jq in its own repos
  install_jq_static || die "$(t env_jq_manual)"
}
ensure_jq

# ---------------------------------------------------------------------------
# probes — each prints a JSON fragment on stdout
# ---------------------------------------------------------------------------
tool_json() {  # <name> → {path,version,ok} or {ok:false}
  local name=$1 path ver
  path=$(command -v "$name" 2>/dev/null)
  if [ -z "$path" ]; then
    jq -cn '{ok:false}'
    return 0
  fi
  ver=$("$name" --version 2>&1 | head -1)
  jq -cn --arg p "$path" --arg v "$ver" '{path:$p,version:$v,ok:true}'
}

find_jdk() {  # <8|17> → echo jdk dir (has bin/javac) or nothing
  local d
  case "$1" in
    8)
      for d in /usr/lib/jvm/java-1.8.0-openjdk-* /usr/lib/jvm/java-8-openjdk-*; do
        [ -x "$d/bin/javac" ] && { printf '%s' "$d"; return 0; }
      done ;;
    17)
      # java-17-* covers both distro packages (java-17-openjdk-*) and the
      # Temurin tarball the installers drop in (java-17-adoptium)
      for d in /usr/lib/jvm/java-17-*; do
        [ -x "$d/bin/javac" ] && { printf '%s' "$d"; return 0; }
      done ;;
  esac
  return 1
}

jdk_json() {  # <8|17>
  local dir ver
  dir=$(find_jdk "$1") || { jq -cn '{ok:false}'; return 0; }
  ver=$("$dir/bin/java" -version 2>&1 | head -1)
  jq -cn --arg p "$dir" --arg v "$ver" '{path:$p,version:$v,ok:true}'
}

env_vars_json() {  # JAVA_HOME: set and pointing at a usable JDK
  local jh="${JAVA_HOME:-}"
  if [ -n "$jh" ] && [ -x "$jh/bin/javac" ]; then
    jq -cn --arg v "$jh" '{JAVA_HOME:{value:$v,ok:true}}'
  elif [ -n "$jh" ]; then
    jq -cn --arg v "$jh" '{JAVA_HOME:{value:$v,ok:false}}'
  else
    jq -cn '{JAVA_HOME:{ok:false}}'
  fi
}

build_tools_json() {  # {tool: bool} — GFVBOT_BUILD_TOOLS probe
  local tool json='{}' present
  for tool in "${GFVBOT_BUILD_TOOLS[@]}"; do
    command -v "$tool" >/dev/null 2>&1 && present=true || present=false
    json=$(jq -cn --arg n "$tool" --argjson p "$present" --argjson j "$json" '$j + {($n):$p}')
  done
  printf '%s' "$json"
}

cpp_deps_json() {  # {lib: bool} — GFVBOT_CPP_DEPS header probe
  local entry lib headers json='{}' present
  for entry in "${GFVBOT_CPP_DEPS[@]}"; do
    lib=${entry%%:*}
    headers=${entry#*:}
    # shellcheck disable=SC2086
    header_exists $headers && present=true || present=false
    json=$(jq -cn --arg n "$lib" --argjson p "$present" --argjson j "$json" '$j + {($n):$p}')
  done
  printf '%s' "$json"
}

agents_json() {  # which AI agent CLIs exist on this machine
  local a present json='{}'
  for a in claude opencode codex dsh; do
    present=false
    command -v "$a" >/dev/null 2>&1 && present=true
    json=$(jq -cn --arg a "$a" --argjson p "$present" --argjson j "$json" '$j + {($a):$p}')
  done
  printf '%s' "$json"
}

system_json() {
  local os_release=/etc/os-release
  local os_name="" os_id="" os_ver=""
  if [ -f "$os_release" ]; then
    os_name=$(grep '^NAME=' "$os_release" | cut -d= -f2- | tr -d '"')
    os_id=$(grep '^ID=' "$os_release" | cut -d= -f2- | tr -d '"')
    os_ver=$(grep '^VERSION_ID=' "$os_release" | cut -d= -f2- | tr -d '"')
  fi
  local cpu_model
  cpu_model=$(lscpu 2>/dev/null | awk -F': +' '/^Model name/{print $2; exit}')
  # aarch64 boards often leave "Model name" empty ("-"); Vendor ID carries it
  [ -n "$cpu_model" ] && [ "$cpu_model" != "-" ] \
    || cpu_model=$(lscpu 2>/dev/null | awk -F': +' '/^Vendor ID/{print $2; exit}')
  local mem_gb disk_gb
  mem_gb=$(free -b 2>/dev/null | awk '/^Mem:/{printf "%.0f", $2/1024/1024/1024}')
  disk_gb=$(df -BG --output=avail / 2>/dev/null | tail -1 | tr -dc '0-9')
  jq -cn \
    --arg on "$os_name" --arg oid "$os_id" --arg ov "$os_ver" \
    --arg k "$(uname -r)" --arg arch "$(uname -m)" \
    --arg cm "$cpu_model" --argjson cores "$(nproc 2>/dev/null || echo 0)" \
    --argjson mem "${mem_gb:-0}" --argjson disk "${disk_gb:-0}" \
    '{os:{name:$on,id:$oid,version:$ov}, kernel:$k, arch:$arch,
      cpu:{model:$cm,cores:$cores}, mem_total_gb:$mem, disk_root_avail_gb:$disk}'
}

flink_root() {  # FLINK_HOME first, then a flink on PATH → root dir or nothing
  if [ -n "${FLINK_HOME:-}" ] && [ -x "$FLINK_HOME/bin/flink" ]; then
    printf '%s' "$FLINK_HOME"
    return 0
  fi
  local p
  p=$(command -v flink 2>/dev/null) || return 1
  printf '%s' "$(dirname "$(dirname "$p")")"
}

stack_json() {  # flink dist + nexmark jar under its lib/
  local froot fver="" fpath="" njar="" nver=""
  if froot=$(flink_root); then
    fpath=$froot
    fver=$("$froot/bin/flink" --version 2>&1 | head -1)
    njar=$(ls "$froot"/lib/*nexmark*.jar 2>/dev/null | head -1)
    [ -n "$njar" ] && nver=$(basename "$njar" | sed -n 's/.*nexmark[^0-9]*\([0-9][0-9.]*\(-[A-Za-z][A-Za-z0-9]*\)\?\).*/\1/p' | sed 's/\.$//')
  fi
  local flink_j nexmark_j
  if [ -n "$fpath" ]; then
    flink_j=$(jq -cn --arg p "$fpath" --arg v "$fver" '{path:$p,version:$v,ok:true}')
  else
    flink_j=$(jq -cn '{ok:false}')
  fi
  if [ -n "$njar" ]; then
    nexmark_j=$(jq -cn --arg p "$njar" --arg v "$nver" '{path:$p,version:$v,ok:true}')
  else
    nexmark_j=$(jq -cn '{ok:false}')
  fi
  jq -cn --argjson f "$flink_j" --argjson n "$nexmark_j" '{flink:$f, nexmark:$n}'
}

repos_json() {  # {name:{ok:false}} placeholders; a repos section captured in
                # REPOS_CARRY (written by `gfvbot clone`, or by hand) is
                # carried over untouched so a re-scan never loses paths
  local e n json
  if [ -n "$REPOS_CARRY" ]; then
    printf '%s' "$REPOS_CARRY"
    return 0
  fi
  json='{}'
  for e in "${GFVBOT_REPOS[@]}"; do
    n=${e%%|*}
    json=$(jq -cn --arg n "$n" --argjson j "$json" '$j + {($n):{ok:false}}')
  done
  printf '%s' "$json"
}

scan_env() {  # → full env.json content on stdout
  local tools='{}' t
  for t in git cmake gcc g++ mvn; do
    tools=$(jq -cn --arg t "$t" --argjson o "$(tool_json "$t")" --argjson j "$tools" '$j + {($t):$o}')
  done
  jq -n \
    --arg ca "$(date -Iseconds)" \
    --argjson system "$(system_json)" \
    --argjson tools "$tools" \
    --argjson bt "$(build_tools_json)" \
    --argjson cd "$(cpp_deps_json)" \
    --argjson j8 "$(jdk_json 8)" \
    --argjson j17 "$(jdk_json 17)" \
    --argjson envvars "$(env_vars_json)" \
    --argjson agents "$(agents_json)" \
    --argjson stack "$(stack_json)" \
    --argjson repos "$(repos_json)" \
    '{checked_at:$ca, system:$system, tools:$tools,
      build_tools:$bt, cpp_deps:$cd,
      jdks:{"8":$j8, "17":$j17}, env:$envvars, agents:$agents, stack:$stack,
      repos:$repos}'
}

# ---------------------------------------------------------------------------
# report
# ---------------------------------------------------------------------------
report_group() {  # <env.json> <json-key> <display-name> — one summary line per group
  local j=$1 key=$2 name=$3 total missing
  total=$(jq -r ".$key | length" "$j")
  missing=$(jq -r "[.$key | to_entries[] | select(.value == false) | .key] | join(\" \")" "$j")
  if [ -n "$missing" ]; then
    warn "$(t env_group_missing "$name" "$missing")"
  else
    ok "$name  $total/$total"
  fi
}

report() {  # <env.json>
  local j=$1 name path ver okflag
  echo
  step "$(t env_title)"
  printf '  %-8s %s\n' "os" "$(jq -r '.system.os.name + " " + .system.os.version' "$j")"
  printf '  %-8s %s (%s), %s cores, %sG mem, %sG disk\n' "machine" \
    "$(jq -r '.system.cpu.model' "$j")" "$(jq -r '.system.arch' "$j")" \
    "$(jq -r '.system.cpu.cores' "$j")" \
    "$(jq -r '.system.mem_total_gb' "$j")" "$(jq -r '.system.disk_root_avail_gb' "$j")"
  echo
  report_group "$j" build_tools "build-tools"
  report_group "$j" cpp_deps "cpp-deps"
  echo
  for name in git cmake gcc g++ mvn; do
    okflag=$(jq -r ".tools[\"$name\"].ok" "$j")
    path=$(jq -r ".tools[\"$name\"].path // \"-\"" "$j")
    ver=$(jq -r ".tools[\"$name\"].version // \"-\"" "$j")
    if [ "$okflag" = true ]; then
      ok "$name  $path  $ver"
    else
      warn "$(t env_missing "$name")"
    fi
  done
  local v8 v17
  v8=$(jq -r '.jdks["8"].ok' "$j"); v17=$(jq -r '.jdks["17"].ok' "$j")
  if [ "$v8" = true ]; then
    ok "jdk-8   $(jq -r '.jdks["8"].path' "$j")  $(jq -r '.jdks["8"].version' "$j")"
  else
    warn "$(t env_missing "jdk-8")"
  fi
  if [ "$v17" = true ]; then
    ok "jdk-17  $(jq -r '.jdks["17"].path' "$j")  $(jq -r '.jdks["17"].version' "$j")"
  else
    warn "$(t env_missing "jdk-17")"
  fi
  if [ "$(jq -r '.env.JAVA_HOME.ok' "$j")" = true ]; then
    ok "JAVA_HOME  $(jq -r '.env.JAVA_HOME.value' "$j")"
  else
    warn "$(t env_java_home_unset)"
  fi
  if [ "$(jq -r '.stack.flink.ok' "$j")" = true ]; then
    ok "flink    $(jq -r '.stack.flink.path' "$j")  $(jq -r '.stack.flink.version' "$j")"
  else
    warn "$(t env_missing "flink")"
  fi
  if [ "$(jq -r '.stack.nexmark.ok' "$j")" = true ]; then
    ok "nexmark  $(jq -r '.stack.nexmark.path' "$j")  $(jq -r '.stack.nexmark.version' "$j")"
  else
    warn "$(t env_missing "nexmark")"
  fi
  echo
  local a line=""
  for a in claude opencode codex dsh; do
    if [ "$(jq -r ".agents.$a" "$j")" = true ]; then
      line+="$a ✓  "
    else
      line+="$a ✗  "
    fi
  done
  printf '  agents: %s\n' "$line"
  local unset_repos
  unset_repos=$(jq -r '[.repos | to_entries[] | select(.value.ok != true) | .key] | join(" ")' "$j")
  [ -n "$unset_repos" ] && warn "$(t env_repos_hint "$unset_repos")"
}

# ---------------------------------------------------------------------------
# missing-dependency detection + dispatch to the OS-specific installer
# ---------------------------------------------------------------------------
missing_deps() {  # <env.json> → list of missing dep names (jdk counts as jdk-17
                  # only when neither 8 nor 17 is present; build tools and C++
                  # libs are checked per group — one missing member adds the
                  # group, the installers treat a group as one tick entry)
  local j=$1 m=() t
  for t in git cmake gcc g++ mvn; do
    [ "$(jq -r ".tools[\"$t\"].ok" "$j")" = false ] && m+=("$t")
  done
  if [ "$(jq -r '.jdks["8"].ok' "$j")" = false ] && [ "$(jq -r '.jdks["17"].ok' "$j")" = false ]; then
    m+=("jdk-17")
  fi
  if [ "$(jq -r '[.build_tools[]] | any(. == false)' "$j")" = true ]; then
    m+=("build-tools")
  fi
  if [ "$(jq -r '[.cpp_deps[]] | any(. == false)' "$j")" = true ]; then
    m+=("cpp-deps")
  fi
  printf '%s\n' "${m[@]:-}"
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
ENV_JSON="$TARGET/.gfvbot/env.json"

# capture the existing repos section before write_env's redirect truncates
# the file — repos_json reads this variable, not the file
REPOS_CARRY=""
[ -f "$ENV_JSON" ] && REPOS_CARRY=$(jq -r '.repos // empty' "$ENV_JSON" 2>/dev/null)

write_env() {
  mkdir -p "$TARGET/.gfvbot"
  scan_env | jq . > "$ENV_JSON"
}

write_env
report "$ENV_JSON"
ok "$(t env_saved "$ENV_JSON")"

MISSING=()
while IFS= read -r line; do
  [ -n "$line" ] && MISSING+=("$line")
done < <(missing_deps "$ENV_JSON")

if [ "${#MISSING[@]}" -eq 0 ]; then
  echo
  ok "$(t env_all_present)"
  exit 0
fi

if [ "$(jq -r '.env.JAVA_HOME.ok' "$ENV_JSON")" != true ]; then
  echo
  warn "$(t env_java_home_hint)"
fi

# hand over to the OS-specific installer (env-init/); the installer probes,
# ticks, installs, and re-execs this script so the archive gets refreshed.
SETUP=$(setup_script_for "$(jq -r '.system.os.id' "$ENV_JSON")" "$(jq -r '.system.os.version' "$ENV_JSON")")
if [ -z "$SETUP" ]; then
  echo
  warn "$(t env_os_unsupported "$(jq -r '.system.os.name' "$ENV_JSON")")"
  exit 0
fi

echo
if ! { [ -t 0 ] && [ -t 1 ]; }; then
  warn "$(t env_noninteractive "$SETUP")"
  exit 0
fi

printf '  %s ' "$(t env_ask_install)"
read -r answer
case "$answer" in
  y|Y|yes) exec bash "$SETUP" --target "$TARGET" ;;
  *)       warn "$(t env_run_setup "$SETUP")" ;;
esac
