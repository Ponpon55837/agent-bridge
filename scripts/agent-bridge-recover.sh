#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="$(pwd)"; SESSION=""; FORCE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) [[ $# -ge 2 ]] || { echo "--project requires a value" >&2; exit 1; }; PROJECT_DIR="$2"; shift 2;;
    --session) [[ $# -ge 2 ]] || { echo "--session requires a value" >&2; exit 1; }; SESSION="$2"; shift 2;;
    --force) FORCE=1; shift;;
    *) echo "Usage: $0 [--project DIR] [--session NAME] [--force]" >&2; exit 1;;
  esac
done
PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || { echo "project not found" >&2; exit 1; }
if [[ -z "$SESSION" && -f "$PROJECT_DIR/.ai-bridge.yaml" ]]; then
  SESSION="$(python3 "$ROOT/scripts/config-loader.py" "$PROJECT_DIR/.ai-bridge.yaml" | sed -n 's/^CONFIG_SESSION=//p' | sed "s/^'//; s/'$//")"
fi
[[ -n "$SESSION" ]] || SESSION="$(basename "$PROJECT_DIR")-ai"
[[ "$SESSION" =~ ^[A-Za-z0-9_-]+$ ]] || { echo "invalid session" >&2; exit 1; }
runtime="$PROJECT_DIR/.ai-bridge"; heartbeat="$runtime/state/.supervisor-heartbeat"; pid_file="$runtime/state/supervisor.pid"
if [[ ! -d "$runtime" ]]; then echo "runtime not found: $runtime"; exit 0; fi
if [[ ! -f "$pid_file" || ! -f "$heartbeat" || ! "$(find "$heartbeat" -mmin -1 -print -quit 2>/dev/null)" ]]; then
  if (( ! FORCE )); then
    echo "RECOVERY_REQUIRED session=$SESSION reason=supervisor-stopped-or-stale"
    echo "Re-run with --force to restart once."
    exit 2
  fi
  exec "$ROOT/scripts/agent-bridge" restart --project "$PROJECT_DIR" --session "$SESSION" --detach
fi
echo "RECOVERY_NOT_NEEDED session=$SESSION"
