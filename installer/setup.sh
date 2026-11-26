#!/usr/bin/env bash
# setup.sh — one-time bootstrap: put installer/bin on PATH and mount shell
# completion. Idempotent: rerunning from the same install path changes
# nothing; rerunning from a different install path rewrites the managed
# block with the current path (overwrite install).

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/i18n.sh
. "$ROOT/installer/lib/i18n.sh"
BIN="$ROOT/installer/bin"
MARKER="# gfvbot-setup (managed by GFVBot installer)"
PATH_LINE="export PATH=\"$BIN:\$PATH\""

shell_name=$(basename "${SHELL:-/bin/bash}")

rc_for() {
  case "$shell_name" in
    zsh)  echo "$HOME/.zshrc" ;;
    *)    echo "$HOME/.bashrc" ;;
  esac
}

write_block() {
  {
    echo ""
    echo "$MARKER"
    echo "$PATH_LINE"
    if [ "$shell_name" = "zsh" ]; then
      echo "autoload -U +X bashcompinit && bashcompinit"
      echo "source <(\"$BIN/gfvbot\" completion zsh)"
    else
      echo "source <(\"$BIN/gfvbot\" completion bash)"
    fi
  } >> "$RC"
}

RC=$(rc_for)
[ -f "$RC" ] || touch "$RC"

if ! grep -qF "$MARKER" "$RC"; then
  write_block
  echo "$(t msg_setup_added "$RC")"
elif grep -qF "$PATH_LINE" "$RC"; then
  echo "$(t msg_setup_already "$RC")"
else
  # Marker present but pointing at a different install path: drop the stale
  # block and rewrite it with the current path. Block shape is fixed: the
  # marker, the PATH export, and at most an autoload line plus the
  # completion source line; anything else in the rc is left untouched.
  tmp="$RC.gfvbot.tmp"
  awk -v marker="$MARKER" '
    $0 == marker { skip = 3; next }
    skip > 0 && $0 ~ /^export PATH=".*:\$PATH"$/ { skip--; next }
    skip > 0 && $0 == "autoload -U +X bashcompinit && bashcompinit" { skip--; next }
    skip > 0 && $0 ~ /^source <\(".*" completion (bash|zsh)\)$/ { skip = 0; next }
    { lines[++n] = $0 }
    END {
      while (n > 0 && lines[n] == "") n--
      for (i = 1; i <= n; i++) print lines[i]
    }
  ' "$RC" > "$tmp" && cat "$tmp" > "$RC" && rm -f "$tmp"
  write_block
  echo "$(t msg_setup_updated "$RC")"
fi

echo "$(t msg_setup_next "$RC")"
