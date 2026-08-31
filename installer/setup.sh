#!/usr/bin/env bash
# setup.sh — one-time bootstrap: put installer/bin on PATH and mount shell
# completion. Idempotent: rerunning detects the marker and changes nothing.

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/i18n.sh
. "$ROOT/installer/lib/i18n.sh"
BIN="$ROOT/installer/bin"
MARKER="# gfvbot-setup (managed by GFVBot installer)"

shell_name=$(basename "${SHELL:-/bin/bash}")

rc_for() {
  case "$shell_name" in
    zsh)  echo "$HOME/.zshrc" ;;
    *)    echo "$HOME/.bashrc" ;;
  esac
}

RC=$(rc_for)
[ -f "$RC" ] || touch "$RC"

if grep -qF "$MARKER" "$RC"; then
  echo "$(t msg_setup_already "$RC")"
else
  {
    echo ""
    echo "$MARKER"
    echo "export PATH=\"$BIN:\$PATH\""
    if [ "$shell_name" = "zsh" ]; then
      echo "autoload -U +X bashcompinit && bashcompinit"
      echo "source <(\"$BIN/gfvbot\" completion zsh)"
    else
      echo "source <(\"$BIN/gfvbot\" completion bash)"
    fi
  } >> "$RC"
  echo "$(t msg_setup_added "$RC")"
fi

echo "$(t msg_setup_next "$RC")"
