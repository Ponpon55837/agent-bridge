#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pass=0
check() { "$@"; pass=$((pass + 1)); }
for file in "$ROOT"/scripts/*.sh "$ROOT"/scripts/agent-bridge; do check bash -n "$file"; done
check python3 "$ROOT/scripts/config-loader.py" "$ROOT/.ai-bridge.example.yaml"
check "$ROOT/scripts/runtime-adapter.sh" codex
check "$ROOT/scripts/runtime-adapter.sh" opencode
check "$ROOT/scripts/runtime-adapter.sh" claude
if "$ROOT/scripts/runtime-adapter.sh" invalid >/dev/null 2>&1; then echo "invalid runtime accepted" >&2; exit 1; fi
if "$ROOT/scripts/agent-bridge.sh" --session 'bad:name' --help >/dev/null 2>&1; then :; fi
echo "smoke tests passed: $pass checks"
