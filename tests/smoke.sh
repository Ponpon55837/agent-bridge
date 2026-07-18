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
if "$ROOT/scripts/agent-bridge.sh" --project "$ROOT" --preset invalid --detach >/dev/null 2>&1; then echo "invalid preset accepted" >&2; exit 1; fi
tmp_config_dir="$(mktemp -d "${TMPDIR:-/tmp}/agent-bridge-config.XXXXXX")"
cleanup_config_test() { rm -rf "$tmp_config_dir"; }
trap cleanup_config_test EXIT
cp "$ROOT/.ai-bridge.example.yaml" "$tmp_config_dir/.ai-bridge.yaml"
printf 'session:\n  name: local-session\n' > "$tmp_config_dir/.ai-bridge.local.yaml"
if ! python3 "$ROOT/scripts/config-loader.py" "$tmp_config_dir/.ai-bridge.yaml" | grep -qx "CONFIG_SESSION=local-session"; then
  echo "local config override failed" >&2; exit 1
fi
mkdir -p "$tmp_config_dir/.ai-bridge/state"
"$ROOT/tests/integration-tmux.sh"
if "$ROOT/scripts/agent-bridge-recover.sh" --project "$tmp_config_dir" >/tmp/agent-bridge-recover-check 2>&1; then
  echo "missing runtime recovery check unexpectedly succeeded" >&2; exit 1
fi
grep -q 'RECOVERY_REQUIRED' /tmp/agent-bridge-recover-check
echo "smoke tests passed: $pass checks"
