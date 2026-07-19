#!/usr/bin/env bash
set -euo pipefail
umask 077
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR=""; COPY_CONFIG=0; REFRESH_CONFIG=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) PROJECT_DIR="${2:-}"; shift 2;;
    --copy-config) COPY_CONFIG=1; shift;;
    --refresh-config) COPY_CONFIG=1; REFRESH_CONFIG=1; shift;;
    *) echo "Usage: $0 --project DIR [--copy-config]" >&2; exit 1;;
  esac
done
[[ -n "$PROJECT_DIR" ]] || { echo "--project is required" >&2; exit 1; }
PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || { echo "project not found" >&2; exit 1; }
PROJECT_NAME="$(basename "$PROJECT_DIR")"
DEFAULT_SESSION="$PROJECT_NAME-ai"
gitignore="$PROJECT_DIR/.gitignore"; start='# agent-bridge:start'; end='# agent-bridge:end'
if ! grep -Fqx "$start" "$gitignore" 2>/dev/null; then
  { [[ -s "$gitignore" ]] && printf '\n'; printf '%s\n.ai-bridge/\n.ai-bridge.local.yaml\n.mcp.json\n%s\n' "$start" "$end"; } >> "$gitignore"
fi
if (( REFRESH_CONFIG )) && [[ -e "$PROJECT_DIR/.ai-bridge.yaml" ]]; then
  cp "$PROJECT_DIR/.ai-bridge.yaml" "$PROJECT_DIR/.ai-bridge.yaml.bak"
  echo "已備份舊設定：$PROJECT_DIR/.ai-bridge.yaml.bak"
fi
if (( COPY_CONFIG )) && [[ ! -e "$PROJECT_DIR/.ai-bridge.yaml" ]]; then
  cp "$ROOT/.ai-bridge.example.yaml" "$PROJECT_DIR/.ai-bridge.yaml"
  sed -i.bak "s/^  name: agent-bridge-dev$/  name: $DEFAULT_SESSION/" "$PROJECT_DIR/.ai-bridge.yaml"
  rm -f "$PROJECT_DIR/.ai-bridge.yaml.bak"
  echo "已建立設定：$PROJECT_DIR/.ai-bridge.yaml"
elif [[ -e "$PROJECT_DIR/.ai-bridge.yaml" && $REFRESH_CONFIG -eq 0 ]]; then
  echo "設定已存在，未覆蓋：$PROJECT_DIR/.ai-bridge.yaml"
fi
if (( COPY_CONFIG )); then
  for sample in .ai-bridge.dual.yaml .ai-bridge.quad.yaml; do
    if [[ ! -e "$PROJECT_DIR/$sample" && -e "$ROOT/$sample" ]]; then
      cp "$ROOT/$sample" "$PROJECT_DIR/$sample"
      echo "已建立範例設定：$PROJECT_DIR/$sample"
    fi
  done
fi
mkdir -p "$PROJECT_DIR/.ai-bridge/mailbox" "$PROJECT_DIR/.ai-bridge/state"
echo "INSTALLED project=$PROJECT_DIR"
