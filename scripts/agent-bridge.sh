#!/usr/bin/env bash
set -euo pipefail
umask 077
SESSION_NAME="agent-bridge-dev"
PROJECT_DIR=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRIDGE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
die() { echo "agent-bridge: $*" >&2; exit 1; }
while [[ $# -gt 0 ]]; do
  case "$1" in
    --session) [[ $# -ge 2 ]] || die "--session requires a value"; SESSION_NAME="$2"; shift 2 ;;
    --project) [[ $# -ge 2 ]] || die "--project requires a value"; PROJECT_DIR="$2"; shift 2 ;;
    -h|--help) echo "Usage: $0 [--session NAME] [--project DIR]"; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done
[[ "$SESSION_NAME" =~ ^[A-Za-z0-9_-]+$ ]] || die "invalid session name"
[[ -n "$PROJECT_DIR" ]] || PROJECT_DIR="$BRIDGE_ROOT"
PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || die "project directory does not exist"
RUNTIME_DIR="$PROJECT_DIR/.ai-bridge"
mkdir -p "$RUNTIME_DIR/mailbox" "$RUNTIME_DIR/state"
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  echo "Session '$SESSION_NAME' already exists. Attach with: tmux attach -t $SESSION_NAME"
  exit 0
fi
tmux new-session -d -s "$SESSION_NAME" -c "$PROJECT_DIR"
tmux split-window -h -t "$SESSION_NAME:0" -c "$PROJECT_DIR"
tmux split-window -v -t "$SESSION_NAME:0.0" -c "$PROJECT_DIR"
tmux select-layout -t "$SESSION_NAME:0" tiled
tmux select-pane -t "$SESSION_NAME:0.0" -T orchestrator
tmux select-pane -t "$SESSION_NAME:0.1" -T implementer
tmux select-pane -t "$SESSION_NAME:0.2" -T reviewer
# Pane 0 is intentionally untouched; start the orchestrator CLI manually there.
tmux send-keys -t "$SESSION_NAME:0.1" "opencode" Enter
tmux send-keys -t "$SESSION_NAME:0.2" "opencode" Enter
SUPERVISOR_SCRIPT="$SCRIPT_DIR/supervisor.sh"
if [[ -x "$SUPERVISOR_SCRIPT" ]]; then
  "$SUPERVISOR_SCRIPT" --session "$SESSION_NAME" --project "$PROJECT_DIR" >"$RUNTIME_DIR/state/supervisor.log" 2>&1 &
  echo $! > "$RUNTIME_DIR/state/supervisor.pid"
fi
printf 'session_started %s project=%s\n' "$(date +%s)" "$PROJECT_DIR" >> "$RUNTIME_DIR/state/events.log"
echo "READY session=$SESSION_NAME project=$PROJECT_DIR"
echo "Pane 0 is the orchestrator shell; attach with: tmux attach -t $SESSION_NAME"
