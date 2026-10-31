#!/usr/bin/env bash
# claude.sh — Claude Code adapter.
#
# Layout:
#   skills        → .claude/skills/<name>/
#   agents        → .claude/agents/<plugin>/<name>.md (per-plugin subfolder)
#   workflow      → .claude/gfvbot/index.md (per-plugin sections)
#   entry file    → CLAUDE.md single anchor, body is one @import line
#   docs/templates→ docs/gfvbot/... (uniform, see lib/common.sh)
#   agent-teams   → .claude/settings.json env/teammateMode keys (fill-only)
#   CC bridge     → .gfvbot/marketplace/ + `claude plugin` registration
#                   (agents discoverable as <plugin>:<agent> in claude;
#                   plain .claude/agents/ files register only on first-party
#                   endpoints — the plugin channel is endpoint-independent)

# Claude Code project settings — enable the experimental agent-teams feature
# so a multi-agent gfvbot install works out of the box, and where tmux is
# installed route teammates into tmux panes for a per-teammate view.
# teammateMode is display-only: without tmux, teammates still run headless
# (observable via the /tasks panel), so the key is written only when tmux
# exists on this machine. Fill-only merge: keys the user already set keep
# their values (warned when they differ from the gfvbot defaults). The file
# is user territory — never added to INSTALLED_FILES; uninstall drops only
# the keys that still hold our values.
ensure_team_settings() {  # <target>
  local tgt=$1 s="$1/.claude/settings.json"
  local have_tmux=0
  command -v tmux >/dev/null 2>&1 && have_tmux=1
  local cur_env="" cur_mode=""
  if [ -f "$s" ] && jq -e . "$s" >/dev/null 2>&1; then
    cur_env=$(jq -r '.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS // empty' "$s")
    cur_mode=$(jq -r '.teammateMode // empty' "$s")
  fi
  if [ -n "$DRY_RUN" ]; then
    echo "  $(t dry_write_settings "$s")"
  else
    mkdir -p "$tgt/.claude"
    [ -f "$s" ] || printf '{}\n' > "$s"
    local merge='.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS //= "1"'
    [ "$have_tmux" = 1 ] && merge="$merge | .teammateMode //= \"tmux\""
    local tmp; tmp=$(mktemp)
    if jq "$merge" "$s" > "$tmp" 2>/dev/null; then
      mv "$tmp" "$s"
      ok "$(t msg_settings_done "$s")"
    else
      rm -f "$tmp"
      warn "$(t warn_settings_invalid "$s")"
    fi
  fi
  [ "$have_tmux" = 0 ] && warn "$(t warn_no_tmux)"
  [ -n "$cur_env" ] && [ "$cur_env" != "1" ] \
    && warn "$(t warn_settings_user "env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" "$cur_env")"
  [ "$have_tmux" = 1 ] && [ -n "$cur_mode" ] && [ "$cur_mode" != "tmux" ] \
    && warn "$(t warn_settings_user "teammateMode" "$cur_mode")"
}

adapter_install() {
  local p=$1 m=$2 t=$3
  local u

  while IFS= read -r u; do
    [ -n "$u" ] && idem_install "$PLUGINS_DIR/$p/$CONTENT_LANG/skills/$u" "$t/.claude/skills/$u"
  done < <(jq -r '.skills[]? // empty' "$m")
  while IFS= read -r u; do
    [ -n "$u" ] && idem_install "$SHARED_DIR/$CONTENT_LANG/skills/$u" "$t/.claude/skills/$u"
  done < <(shared_skills "$m")

  while IFS= read -r u; do
    [ -n "$u" ] && idem_install "$PLUGINS_DIR/$p/$CONTENT_LANG/agents/$u.md" "$t/.claude/agents/$p/$u.md"
  done < <(jq -r '.agents[]? // empty' "$m")

  install_docs_templates "$p" "$m" "$t"

  ensure_team_settings "$t"

  local index="$t/.claude/gfvbot/index.md"
  ensure_index "$index"
  local sec; sec=$(mktemp)
  gen_index_section "$p" "$PLUGINS_DIR/$p" workflow_only "$sec"
  section_upsert "$index" "<!-- gfvbot:plugin:$p -->" "<!-- /gfvbot:plugin:$p -->" "$sec"
  # the CC plugin channel names agents <plugin>:<agent> — qualify this
  # plugin's references in the freshly landed section so dispatch resolves
  # in every claude environment (names are globally unique, other sections
  # never match)
  if [ -z "$DRY_RUN" ]; then
    while IFS= read -r u; do
      [ -n "$u" ] && sed -i -E "s/(^|[^:])${u}/\1${p}:${u}/g" "$index"
    done < <(jq -r '.agents[]? // empty' "$m")
  fi
  INSTALLED_FILES+=("$index")

  ensure_cc_bridge "$p" "$m" "$t"

  local entry="$t/CLAUDE.md"
  [ -f "$entry" ] || ENTRY_CREATED=true
  local anchor; anchor=$(mktemp)
  printf '@.claude/gfvbot/index.md\n' > "$anchor"
  section_upsert "$entry" "<!-- gfvbot -->" "<!-- /gfvbot -->" "$anchor"
  INSTALLED_FILES+=("$entry")
}

# ---------------------------------------------------------------------------
# CC plugin channel bridge
#
# Claude Code's plugin channel registers agents as <plugin>:<agent> on every
# endpoint; plain .claude/agents/ files register only on first-party ones.
# The bridge materializes a local marketplace under .gfvbot/marketplace/
# (agent copies with qualified body references, bare frontmatter names) and
# registers it via `claude plugin marketplace add` + `plugin install`, both
# project-scoped and idempotent. Content changes bump the bridge card's
# patch version — the CLI cache is version-keyed and only refreshes then.
# GFVBOT_NO_CC_BRIDGE=1 opts out (plain files still land).
# ---------------------------------------------------------------------------
CC_CLI_PROBED=""

cc_cli_available() {
  if [ -z "$CC_CLI_PROBED" ]; then
    CC_CLI_PROBED=no
    # </dev/null: the CLI reads stdin when attached to a terminal and then
    # waits forever — the very hang this probe is supposed to bound. Closed
    # stdin matches the headless conditions under which the CLI is known to
    # answer promptly.
    if command -v claude >/dev/null 2>&1 \
       && timeout -k 2 15 claude plugin marketplace list </dev/null >/dev/null 2>&1; then
      CC_CLI_PROBED=yes
    fi
  fi
  [ "$CC_CLI_PROBED" = yes ]
}

cc_cli() {  # <target> <args...> — output captured in CC_CLI_OUT, rc passthrough
  local t=$1; shift
  # tight bound + SIGKILL follow-up: a hung or stop-signal-frozen CLI call
  # must never wedge the install (killing stopped processes needs SIGKILL)
  CC_CLI_OUT=$( cd "$t" && timeout -k 3 30 claude "$@" </dev/null 2>&1 )
}

bridge_file() {  # <src> <dst> — generated content: overwrite in place, no .bak
  local src=$1 dst=$2
  if [ -n "$DRY_RUN" ]; then
    echo "  $(t dry_bridge "$dst")"
  else
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
  fi
  INSTALLED_FILES+=("$dst")
}

ensure_cc_bridge() {  # <plugin> <manifest> <target>
  local p=$1 m=$2 t=$3
  local agents; agents=$(jq -r '.agents[]? // empty' "$m")
  [ -n "$agents" ] || return 0

  local mkt="$t/.gfvbot/marketplace"
  local bdir="$mkt/$p"

  # 1. stage qualified-patched agent copies (frontmatter name stays bare —
  #    ':' is invalid there)
  local stage; stage=$(mktemp -d)
  local u
  while IFS= read -r u; do
    [ -n "$u" ] || continue
    sed -E "s/(^|[^:])${u}/\1${p}:${u}/g" \
      "$PLUGINS_DIR/$p/$CONTENT_LANG/agents/$u.md" > "$stage/$u.md"
    sed -i "/^name:/s/${p}:${u}/${u}/" "$stage/$u.md"
  done <<<"$agents"

  # 2. version: identical content keeps it (no CLI refresh needed); content
  #    change bumps the patch component. The minor anchors the content
  #    language (en=0, zh=1): the CLI cache is user-global per
  #    <marketplace>/<plugin>/<version>, so same-version-different-language
  #    installs across projects would share a cache slot — the lang-anchored
  #    minor keeps the realistic collision (a per-project `gfvbot lang zh`)
  #    on separate slots
  local minor=0; [ "$CONTENT_LANG" = zh ] && minor=1
  local ver="1.$minor.0" bumped=0
  if [ -f "$bdir/.claude-plugin/plugin.json" ] && [ -d "$bdir/agents" ] \
     && diff -rq "$stage" "$bdir/agents" >/dev/null 2>&1; then
    ver=$(jq -r '.version // "1.0.0"' "$bdir/.claude-plugin/plugin.json")
  elif [ -f "$bdir/.claude-plugin/plugin.json" ]; then
    local a b c
    IFS=. read -r a b c <<<"$(jq -r '.version // "1.0.0"' "$bdir/.claude-plugin/plugin.json")"
    if [ "${b:-0}" = "$minor" ]; then
      ver="1.$minor.$((${c:-0} + 1))"
    else
      ver="1.$minor.0"
    fi
    bumped=1
  fi

  # 3. bridge plugin card
  local desc
  desc=$(jq -r --arg l "$CONTENT_LANG" \
    'if $l == "zh" then (.description_zh // .description) else (.description // .description_zh) end // "GFVBot plugin"' "$m")
  local card; card=$(mktemp)
  jq -n --arg name "$p" --arg ver "$ver" --arg desc "$desc" \
    '{name: $name, version: $ver, description: $desc}' > "$card"
  bridge_file "$card" "$bdir/.claude-plugin/plugin.json"
  while IFS= read -r u; do
    [ -n "$u" ] && bridge_file "$stage/$u.md" "$bdir/agents/$u.md"
  done <<<"$agents"

  # 4. marketplace manifest FIRST: `plugin marketplace add` reads
  #    <path>/.claude-plugin/marketplace.json on the spot — it must exist
  #    before the call. It is rebuilt after every card drop so a failed
  #    registration is not listed (the CLI must not see a cardless plugin)
  bridge_manifest_build "$mkt" >/dev/null
  INSTALLED_FILES+=("$mkt/.claude-plugin/marketplace.json")

  # 5. register (idempotent) + refresh the CLI cache when content changed.
  #    Invariant: the bridge card exists only after confirmed registration —
  #    whenever registration is not confirmed (no CLI, CLI error) the card
  #    is dropped so the record's health check sees a gap and the next
  #    install re-attempts instead of skipping. Manual mode keeps the card:
  #    registration is the user's to run and the files are their input.
  local reg=1
  if [ -n "$DRY_RUN" ]; then
    echo "  $(t dry_bridge_cli "$p")"
  elif [ -n "${GFVBOT_NO_CC_BRIDGE:-}" ]; then
    ok "$(t msg_bridge_off)"
  elif ! cc_cli_available; then
    warn "$(t warn_no_cc_cli)"
    rm -f "$bdir/.claude-plugin/plugin.json"
    bridge_manifest_build "$mkt" >/dev/null
  else
    echo "  $(t step_bridge_cli)"
    echo "  $(t step_bridge_call "plugin marketplace add")"
    cc_cli "$t" plugin marketplace add "$mkt" --scope project || reg=0
    if [ "$reg" = 1 ]; then
      echo "  $(t step_bridge_call "plugin install $p@$MKT_NAME")"
      cc_cli "$t" plugin install "$p@$MKT_NAME" --scope project || reg=0
    fi
    if [ "$reg" = 0 ]; then
      rm -f "$bdir/.claude-plugin/plugin.json"
      bridge_manifest_build "$mkt" >/dev/null
      warn "$(t warn_bridge_cli "$p" "$p")"
      printf '%s\n' "$CC_CLI_OUT" | sed 's/^/    /'
    else
      ok "$(t msg_bridge_ok "$p")"
      if [ "$bumped" = 1 ]; then
        echo "  $(t step_bridge_call "plugin marketplace update + plugin update")"
        if cc_cli "$t" plugin marketplace update "$MKT_NAME" \
           && cc_cli "$t" plugin update "$p@$MKT_NAME" --scope project; then
          ok "$(t msg_bridge_updated "$ver")"
        else
          warn "$(t warn_bridge_update "$p")"
          printf '%s\n' "$CC_CLI_OUT" | sed 's/^/    /'
        fi
      fi
    fi
  fi
}
