#!/usr/bin/env bash
# GFVBot plugin thin entry — forwards to the install engine with this plugin pre-filled.
# Plugin-specific install logic is forbidden here; tests/unit enforces this file stays
# byte-identical to the standard template.
exec "$(cd "$(dirname "$0")/../.." && pwd)/installer/install.sh" --plugin "$(basename "$(dirname "$0")")" "$@"
