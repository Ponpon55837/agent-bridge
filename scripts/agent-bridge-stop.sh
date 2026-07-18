#!/usr/bin/env bash
set -euo pipefail
SESSION_NAME="agent-bridge-dev"; PROJECT_DIR="$(pwd)"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --session) SESSION_NAME="$2"; shift 2;;
    --project) PROJECT_DIR="$2"; shift 2;;
    *) echo "Usage: $0 [--session NAME] [--project DIR]" >&2; exit 1;;
  esac
done
[[ "$SESSION_NAME" =~ ^[A-Za-z0-9_-]+$ ]] || { echo "invalid session" >&2; exit 1; }
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"; PID_FILE="$PROJECT_DIR/.ai-bridge/state/supervisor.pid"
if [[ -f "$PID_FILE" ]]; then
  supervisor_pid="$(<"$PID_FILE")"
  if [[ "$supervisor_pid" =~ ^[0-9]+$ ]]; then
    supervisor_command="$(ps -p "$supervisor_pid" -o command= 2>/dev/null || true)"
    if [[ "$supervisor_command" == *"supervisor.sh"* && "$supervisor_command" == *"--session $SESSION_NAME"* && "$supervisor_command" == *"--project $PROJECT_DIR"* ]]; then
      kill "$supervisor_pid" 2>/dev/null || true
    fi
  fi
  rm -f "$PID_FILE"
fi
tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
echo "STOPPED session=$SESSION_NAME"
