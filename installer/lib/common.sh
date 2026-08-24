#!/usr/bin/env bash
# common.sh — shared helpers for GFVBot installer engine and adapters.
# Sourced by install.sh / uninstall.sh / adapters; not executable on its own.

# shellcheck source=lib/i18n.sh
. "$(dirname "${BASH_SOURCE[0]}")/i18n.sh"

# ---------------------------------------------------------------------------
# logging
# ---------------------------------------------------------------------------
ok()   { printf '  \033[32m✔\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m⚠\033[0m %s\n' "$*"; }
err()  { printf '  \033[31m✘\033[0m %s\n' "$*" >&2; }
step() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
die()  { err "$*"; exit 1; }

require_jq() {
  command -v jq >/dev/null 2>&1 || { err "jq is required but not found in PATH"; exit 1; }
}

# package manager used for dependency bootstrap (dnf / yum / apt-get, or empty)
detect_pm() {
  if command -v dnf >/dev/null 2>&1; then echo dnf
  elif command -v yum >/dev/null 2>&1; then echo yum
  elif command -v apt-get >/dev/null 2>&1; then echo apt-get
  else echo ""
  fi
}

# ---------------------------------------------------------------------------
# jq static-binary fallback — for distros whose repos carry no jq package
# (e.g. CentOS 7, where jq lives in the EOL'd EPEL). rc 1 = download failed.
# ---------------------------------------------------------------------------
install_jq_static() {
  local arch=$(uname -m) url
  case "$arch" in
    aarch64) arch=arm64 ;;
    x86_64)  arch=amd64 ;;
    *) return 1 ;;
  esac
  url="https://github.com/jqlang/jq/releases/download/jq-1.8.0/jq-linux-$arch"
  echo "  $(t env_installing_jq_static "$url")"
  curl -fsSL --retry 3 --max-time 120 -o /usr/local/bin/jq "$url" \
    && chmod +x /usr/local/bin/jq
}

# ---------------------------------------------------------------------------
# GFV build dependency table — the pieces Velox's official setup scripts
# install from the system package manager: build tool prerequisites plus the
# dnf-level C++ libraries. Libraries Velox builds from source (gflags, glog,
# folly, boost, protobuf, ...) are deliberately absent: GFV's CMake resolves
# those via BUNDLED FetchContent, so they need no system package.
# Shared by env.sh (scan / report) and env-init scripts (probe / install).
# ---------------------------------------------------------------------------
GFVBOT_BUILD_TOOLS=(ninja ccache autoconf automake libtool flex bison python3)

# <lib>:<header candidates> — probed under both /usr/include and
# /usr/local/include (source installs land in the latter); a lib may list
# several candidates (libdwarf ships libdwarf.h, libdwarf-0/libdwarf.h, or
# libdwarf/libdwarf.h depending on distro and version).
GFVBOT_CPP_DEPS=(
  "libevent:event2/event.h"
  "openssl:openssl/ssl.h"
  "re2:re2/re2.h"
  "zstd:zstd.h"
  "lz4:lz4.h"
  "double-conversion:double-conversion/double-conversion.h"
  "libdwarf:libdwarf.h libdwarf-0/libdwarf.h libdwarf/libdwarf.h"
  "libelf:libelf.h"
  "curl:curl/curl.h"
  "icu:unicode/uversion.h"
  "sodium:sodium.h"
  "zlib:zlib.h"
)

header_exists() {  # <header>... → rc 0 when any candidate is on disk
  local h
  for h in "$@"; do
    [ -f "/usr/include/$h" ] && return 0
    [ -f "/usr/local/include/$h" ] && return 0
  done
  return 1
}

build_tool_missing() {  # → missing tool names, space separated
  local tool out=""
  for tool in "${GFVBOT_BUILD_TOOLS[@]}"; do
    command -v "$tool" >/dev/null 2>&1 || out+="$tool "
  done
  printf '%s' "${out% }"
}

cpp_dep_missing() {  # → missing lib names, space separated
  local entry lib headers out=""
  for entry in "${GFVBOT_CPP_DEPS[@]}"; do
    lib=${entry%%:*}
    headers=${entry#*:}
    # shellcheck disable=SC2086
    header_exists $headers || out+="$lib "
  done
  printf '%s' "${out% }"
}

# setup_script_for <os-id> <os-version> → matching env-init script, or nothing.
# Callers must have ROOT (repo root) defined. Used by env.sh (check handover)
# and the gfvbot CLI (env-init subcommand).
setup_script_for() {
  case "$1" in
    openEuler|openeuler)
      printf '%s' "$ROOT/installer/env-init/setup-openEuler.sh" ;;
    centos)
      case "$2" in
        7*) printf '%s' "$ROOT/installer/env-init/setup-centos7.sh" ;;
        9*) printf '%s' "$ROOT/installer/env-init/setup-centos9.sh" ;;
      esac ;;
  esac
}

# ---------------------------------------------------------------------------
# GFV source repos — what `gfvbot clone` lays down under <target>/repos/<name>
# so every machine gets the same workspace layout. Cloning is the CLI's only
# job here: once a repo exists, all version control is plain git territory.
# <name>|<baseline_url>|<branch>|<fork> — '|' as separator: the https URLs
# contain colons. baseline_url is the GFV lineage upstream (bigo-sg carries
# gluten-0530 for velox/velox4j, apache for gluten/flink). <fork> marks
# whether --fork <user> may swap the owner to github.com/<user>/<repo> at the
# same branch; empty = the repo is not forkable and always clones from the
# baseline upstream (flink pins release-1.19).
# ---------------------------------------------------------------------------
GFVBOT_REPOS=(
  "velox|https://github.com/bigo-sg/velox.git|gluten-0530|yes"
  "velox4j|https://github.com/bigo-sg/velox4j.git|gluten-0530|yes"
  "gluten|https://github.com/apache/gluten.git|main|yes"
  "flink|https://github.com/apache/flink.git|release-1.19|"
)

repo_entry() { local e; for e in "${GFVBOT_REPOS[@]}"; do [ "${e%%|*}" = "$1" ] && { printf '%s' "$e"; return 0; }; done; return 1; }
repo_forkable() { local e; e=$(repo_entry "$1") || return 1; printf '%s' "${e##*|}"; }
repo_url() {
  local fk; fk=$(repo_forkable "$1") || return 1
  if [ -n "$2" ] && [ -n "$fk" ]; then printf 'https://github.com/%s/%s.git' "$2" "$1"; return 0; fi
  local e; e=$(repo_entry "$1"); local r=${e#*|}; printf '%s' "${r%%|*}"
}
repo_branch() { local e; e=$(repo_entry "$1") || return 1; local r=${e#*|}; r=${r#*|}; printf '%s' "${r%%|*}"; }

# ---------------------------------------------------------------------------
# CentOS 7 EOL recovery — upstream mirrors are gone, so yum sees zero packages.
# After asking for confirmation, point /etc/yum.repos.d/CentOS-Base.repo at an
# archive mirror (original kept as *.gfvbot.bak). No-op on other distros and
# on hosts whose repos still resolve. rc 1 = repos unusable (declined,
# headless, or the switch failed).
# ---------------------------------------------------------------------------
_centos_archive_probe() {  # <base> → prints URL when its repodata answers
  local base=$1 arch path
  arch=$(uname -m)
  case "$arch" in
    aarch64) path="altarch/7.9.2009/os/$arch/repodata/repomd.xml" ;;
    *)       case "$base" in
               */centos-vault) path="7.9.2009/os/$arch/repodata/repomd.xml" ;;
               *)              path="centos/7.9.2009/os/$arch/repodata/repomd.xml" ;;
             esac ;;
  esac
  curl -sI --max-time 8 -o /dev/null -w '%{http_code}' "$base/$path" 2>/dev/null \
    | grep -q 200 && printf '%s' "$base/$path"
}

_centos_repo_pkgs() {  # total package count across repos (0 = dead mirrors)
  local pm=yum
  command -v yum >/dev/null 2>&1 || pm=dnf   # CentOS 9 is dnf-only
  # no -q here: the quiet form drops the status column on dnf, and the count
  # lives in that column
  $pm repolist 2>/dev/null \
    | awk '$1 !~ /^repo/ && NF {gsub(/,/, "", $NF); sum += $NF} END {print sum + 0}'
}

ensure_centos_repos() {
  local osid="" osver=""
  [ -f /etc/os-release ] && osid=$(sed -n 's/^ID=//p' /etc/os-release | head -1 | tr -d '"')
  [ "$osid" = centos ] || return 0
  # only 7 is EOL; 9+ repos are alive and must not be touched
  osver=$(sed -n 's/^VERSION_ID=//p' /etc/os-release | head -1 | tr -d '"' | cut -d. -f1)
  case "$osver" in 7*) ;; *) return 0 ;; esac
  # repolist stays rc=0 even with dead mirrors; the giveaway is that every
  # repo reports zero packages (quiet mode prints no summary line)
  local pkgs
  pkgs=$(_centos_repo_pkgs)
  [ "$pkgs" -eq 0 ] 2>/dev/null || return 0
  warn "$(t env_repos_broken)"
  if ! { [ -t 0 ] && [ -t 1 ]; }; then
    warn "$(t env_repos_noninteractive "$0")"
    return 1
  fi
  local base=""
  local b
  for b in https://mirrors.aliyun.com/centos-vault https://vault.centos.org; do
    if [ -n "$(_centos_archive_probe "$b")" ]; then base=$b; break; fi
  done
  if [ -z "$base" ]; then
    warn "$(t env_repos_fix_failed)"
    return 1
  fi
  printf '  %s ' "$(t env_ask_fix_repos "$base")"
  local answer
  read -r answer
  case "$answer" in
    y|Y|yes) ;;
    *) warn "$(t env_repos_fix_failed)"; return 1 ;;
  esac
  local repo=/etc/yum.repos.d/CentOS-Base.repo
  cp "$repo" "$repo.gfvbot.bak"
  sed -i -e 's|^mirrorlist=|#mirrorlist=|g' -e 's|\$releasever|7.9.2009|g' "$repo"
  case "$base" in
    */centos-vault)  # archive layout drops the centos/ segment aliyun-side
      sed -i -e 's|^#baseurl=http://mirror.centos.org/centos/|baseurl='"$base"'/|g' \
             -e 's|^#baseurl=http://mirror.centos.org/altarch/|baseurl='"$base"'/altarch/|g' "$repo" ;;
    *)
      sed -i -e 's|^#baseurl=http://mirror.centos.org|baseurl='"$base"'|g' "$repo" ;;
  esac
  yum clean all >/dev/null 2>&1
  pkgs=$(_centos_repo_pkgs)
  if [ "$pkgs" -eq 0 ] 2>/dev/null; then
    warn "$(t env_repos_fix_failed)"
    return 1
  fi
  ok "$(t env_repos_fixed "$base" "$repo.gfvbot.bak")"
}

# repo root = parent of installer/
gfvbot_root() { dirname "$(dirname "$(realpath "${BASH_SOURCE[1]}")")"; }

# ---------------------------------------------------------------------------
# anchored-section primitives (single-anchor territory)
#
# A section is delimited by exact marker lines:
#     <!-- gfvbot:... -->        start
#     <!-- /gfvbot:... -->       end
# Inside the markers is GFVBot territory; outside is user content.
# ---------------------------------------------------------------------------

section_exists() {
  local file=$1 start=$2
  [ -f "$file" ] && grep -qFx "$start" "$file"
}

# section_upsert <file> <start> <end> <content_file>
# Replace section body if markers exist, else append the whole section at EOF.
# content_file must NOT contain the marker lines themselves.
section_upsert() {
  local file=$1 start=$2 end=$3 content=$4
  if [ -n "$DRY_RUN" ]; then
    if section_exists "$file" "$start"; then
      echo "  $(t dry_update_sec "$file")"
    else
      echo "  $(t dry_append_sec "$file")"
    fi
    return 0
  fi
  mkdir -p "$(dirname "$file")"
  touch "$file"
  local tmp; tmp=$(mktemp)
  if section_exists "$file" "$start"; then
    awk -v start="$start" -v end="$end" -v content="$content" '
      BEGIN { in_sec = 0; done = 0 }
      $0 == start {
        in_sec = 1
        if (!done) {
          print start
          while ((getline line < content) > 0) print line
          close(content)
          done = 1
        }
        print end
        next
      }
      in_sec && $0 == end { in_sec = 0; next }
      !in_sec { print }
    ' "$file" > "$tmp"
  else
    { cat "$file"; echo "$start"; cat "$content"; echo "$end"; } > "$tmp"
  fi
  mv "$tmp" "$file"
}

# section_remove <file> <start> <end>  → returns 0 if the section existed
section_remove() {
  local file=$1 start=$2 end=$3
  if [ ! -f "$file" ]; then
    return 1
  fi
  if ! section_exists "$file" "$start"; then
    return 1
  fi
  if [ -n "$DRY_RUN" ]; then
    echo "  $(t dry_remove_sec "$file")"
    return 0
  fi
  local tmp; tmp=$(mktemp)
  awk -v start="$start" -v end="$end" '
    BEGIN { in_sec = 0 }
    $0 == start { in_sec = 1; next }
    in_sec && $0 == end { in_sec = 0; next }
    !in_sec { print }
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
  return 0
}

# ---------------------------------------------------------------------------
# idempotent content install
#
# idem_install <src> <dst>
#   copy mode  : skip when identical; back up diverged destination first
#   link mode  : symlink to the repo source (source updates propagate)
# Tracks every landing path in INSTALLED_FILES.
# ---------------------------------------------------------------------------
INSTALLED_FILES=()

idem_install() {
  local src=$1 dst=$2
  if [ ! -e "$src" ]; then
    err "$(t err_source_missing "$src")"
    return 1
  fi
  if [ -n "$LINK_MODE" ]; then
    if [ -n "$DRY_RUN" ]; then
      echo "  $(t dry_link "$src" "$dst")"
    else
      mkdir -p "$(dirname "$dst")"
      rm -rf "$dst"
      ln -sfn "$(realpath "$src")" "$dst"
    fi
  else
    local same=0
    if [ -d "$src" ]; then
      [ -d "$dst" ] && diff -rq "$src" "$dst" >/dev/null 2>&1 && same=1
    else
      [ -f "$dst" ] && cmp -s "$src" "$dst" && same=1
    fi
    if [ "$same" = 1 ]; then
      :
    elif [ -n "$DRY_RUN" ]; then
      echo "  $(t dry_install "$src" "$dst")"
    else
      mkdir -p "$(dirname "$dst")"
      if [ -e "$dst" ] || [ -L "$dst" ]; then
        local bak; bak="${dst}.gfvbot.bak.$(date +%Y%m%d%H%M%S)"
        warn "$(t warn_diverged "$dst" "$bak")"
        mv "$dst" "$bak"
      fi
      if [ -d "$src" ]; then
        cp -R "$src" "$dst"
      else
        cp "$src" "$dst"
      fi
    fi
  fi
  INSTALLED_FILES+=("$dst")
}

# ---------------------------------------------------------------------------
# index section generation
#
# The per-tool index file carries one section per plugin:
#     <!-- gfvbot:plugin:<name> --> ... <!-- /gfvbot:plugin:<name> -->
# claude / opencode: workflow text only (agents live in their own files).
# codex / dsh      : workflow text + agent definitions merged as member
#                    sections (no native sub-agent file mechanism to rely on).
# ---------------------------------------------------------------------------
gen_index_section() {
  local plugin=$1 plugin_dir=$2 mode=$3 out=$4
  {
    echo "## Plugin: ${plugin}"
    echo
    cat "$plugin_dir/workflow.md"
    if [ "$mode" = "with_agents" ]; then
      local agent
      while IFS= read -r agent; do
        [ -z "$agent" ] && continue
        echo
        echo "### Agent: ${agent}"
        echo
        cat "$plugin_dir/agents/${agent}.md"
      done < <(jq -r '.agents[]? // empty' "$plugin_dir/plugin.json")
    fi
  } > "$out"
}

# reverse mapping: which index file a tool's install maintains
index_path() {
  case "$1" in
    claude)   echo "$2/.claude/gfvbot/index.md" ;;
    opencode) echo "$2/.opencode/gfvbot/index.md" ;;
    codex)    echo "$2/.codex/gfvbot/index.md" ;;
    dsh)      echo "$2/.agents/gfvbot/index.md" ;;
  esac
}

# index file bootstrap: create with a static header on first landing
ensure_index() {
  local index=$1
  [ -f "$index" ] && return 0
  if [ -n "$DRY_RUN" ]; then
    echo "  $(t dry_create_index "$index")"
  else
    mkdir -p "$(dirname "$index")"
    printf '# GFVBot Workflows\n' > "$index"
  fi
}

# ---------------------------------------------------------------------------
# docs & templates landing (identical across all four AI agents)
#   plugin-owned : docs/gfvbot/<plugin>/<unit>
#   shared       : docs/gfvbot/shared/<unit>            (docs)
#                  docs/gfvbot/shared/templates/<unit>  (templates)
# Reference-counted on uninstall via shared_refs in the install record.
# ---------------------------------------------------------------------------
install_docs_templates() {
  local plugin=$1 manifest=$2 target=$3
  local unit
  while IFS= read -r unit; do
    [ -z "$unit" ] && continue
    idem_install "$PLUGINS_DIR/$plugin/docs/$unit" "$target/docs/gfvbot/$plugin/$unit"
  done < <(jq -r '.docs[]? // empty' "$manifest")
  while IFS= read -r unit; do
    [ -z "$unit" ] && continue
    idem_install "$PLUGINS_DIR/$plugin/templates/$unit" "$target/docs/gfvbot/$plugin/templates/$unit"
  done < <(jq -r '.templates[]? // empty' "$manifest")
  while IFS= read -r unit; do
    [ -z "$unit" ] && continue
    idem_install "$SHARED_DIR/docs/$unit" "$target/docs/gfvbot/shared/$unit"
  done < <(jq -r '.shared.docs[]? // empty' "$manifest")
  while IFS= read -r unit; do
    [ -z "$unit" ] && continue
    idem_install "$SHARED_DIR/templates/$unit" "$target/docs/gfvbot/shared/templates/$unit"
  done < <(jq -r '.shared.templates[]? // empty' "$manifest")
}

# shared skills landing path per tool layout is decided by the adapter;
# enumerate shared units for adapters to loop over.
shared_skills() { jq -r '.shared.skills[]? // empty' "$1"; }

# ---------------------------------------------------------------------------
# install record (single source of truth for the installed state)
# Globals read: INSTALLED_FILES, ENTRY_CREATED ("true"/"false"), FINGERPRINT
# ---------------------------------------------------------------------------
record_path() { echo "$1/.gfvbot/records/$2.$3.json"; }

record_write() {
  local target=$1 plugin=$2 tool=$3 link_flag=$4
  local rec; rec=$(record_path "$target" "$plugin" "$tool")
  if [ -n "$DRY_RUN" ]; then
    echo "  $(t dry_write_record "$rec")"
    return 0
  fi
  mkdir -p "$(dirname "$rec")"
  local files_json
  files_json=$(printf '%s\n' "${INSTALLED_FILES[@]:-}" | jq -R . | jq -s 'map(select(length > 0))')
  local snapshot_json
  snapshot_json=$(jq -cS . "$PLUGINS_DIR/$plugin/plugin.json")
  local shared_json
  shared_json=$(jq -c '{skills: (.shared.skills // []), docs: (.shared.docs // []), templates: (.shared.templates // [])}' "$PLUGINS_DIR/$plugin/plugin.json")
  local entry_json; entry_json=${ENTRY_CREATED:-false}
  jq -n \
    --arg plugin "$plugin" \
    --arg tool "$tool" \
    --argjson link "$link_flag" \
    --argjson files "$files_json" \
    --argjson shared "$shared_json" \
    --argjson snapshot "$snapshot_json" \
    --argjson entry_created "$entry_json" \
    --arg fingerprint "${FINGERPRINT:-}" \
    --arg installed_at "$(date -Iseconds)" \
    --arg version "1" \
    '{plugin: $plugin, tool: $tool, link: $link, files: $files, shared_refs: $shared,
      snapshot: $snapshot, entry_created: $entry_created, fingerprint: $fingerprint,
      installed_at: $installed_at, record_version: $version}' \
    > "$rec"
}

# ---------------------------------------------------------------------------
# generic interactive tick-list — items are plain display strings.
# ui_pick <title-msg-key> <hint-msg-key> <item>... → PICKED=(), rc 1 = cancelled
# Requires a real terminal; callers gate on [ -t 0 ] && [ -t 1 ].
# ---------------------------------------------------------------------------
ui_pick() {
  local title_key=$1 hint_key=$2
  shift 2
  local items=("$@")
  local n=$#
  local -a checked=()
  local i
  for ((i = 0; i < n; i++)); do checked[$i]=1; done
  local cur=0 key sub
  local saved_tty
  saved_tty=$(stty -g)
  stty raw -echo min 1 time 0    # own the terminal: keys arrive byte-wise
  _pick_fini() { stty "$saved_tty"; printf '\033[?25h'; }
  printf '\033[?25l'            # hide cursor
  t "$title_key"; echo
  t "$hint_key"; echo
  echo
  _pick_paint() {
    local i mark ptr
    for ((i = 0; i < n; i++)); do
      [ "${checked[$i]}" = 1 ] && mark="✔" || mark=" "
      [ "$i" = "$cur" ] && ptr=">" || ptr=" "
      printf '  %s %s %s\n' "$ptr" "$mark" "${items[$i]}"
    done
  }
  _pick_paint
  while true; do
    # -N (not -n): read the byte verbatim — -n would swallow CR/LF as line
    # delimiters and Enter would never reach the case below
    if ! IFS= read -rsN1 key; then
      _pick_fini                # EOF on stdin — refuse to spin, bail out
      return 1
    fi
    if [[ "$key" == $'\x1b' ]]; then
      IFS= read -rsN2 sub
      case "$sub" in
        '[A') key=UP ;;
        '[B') key=DOWN ;;
      esac
    fi
    case "$key" in
      j|DOWN) [ "$cur" -lt $((n - 1)) ] && cur=$((cur + 1)) ;;
      k|UP)   [ "$cur" -gt 0 ] && cur=$((cur - 1)) ;;
      ' '|x)  checked[$cur]=$((1 - ${checked[$cur]})) ;;
      $'\r'|$'\n') break ;;
      q|Q)    _pick_fini; return 1 ;;
    esac
    printf '\033[%dA' "$n"
    _pick_paint
  done
  _pick_fini
  PICKED=()
  for ((i = 0; i < n; i++)); do
    [ "${checked[$i]}" = 1 ] && PICKED+=("${items[$i]}")
  done
  return 0   # explicit: the for-loop tail would otherwise leak its status
}
