#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR=""; COPY_CONFIG=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) PROJECT_DIR="${2:-}"; shift 2;;
    --copy-config) COPY_CONFIG=1; shift;;
    *) echo "Usage: $0 --project DIR [--copy-config]" >&2; exit 1;;
  esac
done
[[ -n "$PROJECT_DIR" ]] || { echo "--project is required" >&2; exit 1; }
PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || { echo "project not found" >&2; exit 1; }
gitignore="$PROJECT_DIR/.gitignore"; start='# agent-bridge:start'; end='# agent-bridge:end'
if ! grep -Fqx "$start" "$gitignore" 2>/dev/null; then
  { [[ -s "$gitignore" ]] && printf '\n'; printf '%s\n.ai-bridge/\n.ai-bridge.local.yaml\n.mcp.json\n%s\n' "$start" "$end"; } >> "$gitignore"
fi
if (( COPY_CONFIG )) && [[ ! -e "$PROJECT_DIR/.ai-bridge.yaml" ]]; then cp "$ROOT/.ai-bridge.example.yaml" "$PROJECT_DIR/.ai-bridge.yaml"; fi
mkdir -p "$PROJECT_DIR/.ai-bridge/mailbox" "$PROJECT_DIR/.ai-bridge/state"
echo "INSTALLED project=$PROJECT_DIR"
