#!/usr/bin/env bash
set -euo pipefail
umask 077
SESSION_NAME="agent-bridge-dev"
PROJECT_DIR=""
CONFIG_FILE=""
IMPLEMENTER_PANE=1
REVIEWER_PANE=2
ORCHESTRATOR_PANE=0
IMPLEMENTER_ROLE="implementation"
REVIEWER_ROLE="review"
PANE_COUNT=3
IMPLEMENTER_RUNTIME="opencode"
REVIEWER_RUNTIME="opencode"
ORCHESTRATOR_RUNTIME="codex"
ATTACH=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRIDGE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
die() { echo "agent-bridge: $*" >&2; exit 1; }
while [[ $# -gt 0 ]]; do
  case "$1" in
    --session) [[ $# -ge 2 ]] || die "--session requires a value"; SESSION_NAME="$2"; shift 2 ;;
    --project) [[ $# -ge 2 ]] || die "--project requires a value"; PROJECT_DIR="$2"; shift 2 ;;
    --config) [[ $# -ge 2 ]] || die "--config requires a value"; CONFIG_FILE="$2"; shift 2 ;;
    --panes) [[ $# -ge 2 ]] || die "--panes requires a value"; PANE_COUNT="$2"; shift 2 ;;
    --implementer-runtime) [[ $# -ge 2 ]] || die "--implementer-runtime requires a value"; IMPLEMENTER_RUNTIME="$2"; shift 2 ;;
    --reviewer-runtime) [[ $# -ge 2 ]] || die "--reviewer-runtime requires a value"; REVIEWER_RUNTIME="$2"; shift 2 ;;
    --orchestrator-runtime) [[ $# -ge 2 ]] || die "--orchestrator-runtime requires a value"; ORCHESTRATOR_RUNTIME="$2"; shift 2 ;;
    --detach) ATTACH=0; shift ;;
    --attach) ATTACH=1; shift ;;
    -h|--help) echo "Usage: $0 [--session NAME] [--project DIR]"; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done
[[ "$SESSION_NAME" =~ ^[A-Za-z0-9_-]+$ ]] || die "invalid session name"
[[ "$PANE_COUNT" =~ ^[3-9][0-9]*$ ]] || die "panes must be an integer >= 3"
[[ -n "$PROJECT_DIR" ]] || PROJECT_DIR="$BRIDGE_ROOT"
PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || die "project directory does not exist"
[[ -n "$CONFIG_FILE" ]] || [[ ! -f "$PROJECT_DIR/.ai-bridge.yaml" ]] || CONFIG_FILE="$PROJECT_DIR/.ai-bridge.yaml"
if [[ -n "$CONFIG_FILE" ]]; then
  [[ -f "$CONFIG_FILE" ]] || die "config file does not exist: $CONFIG_FILE"
  eval "$(python3 "$SCRIPT_DIR/config-loader.py" "$CONFIG_FILE")"
  [[ "$SESSION_NAME" == "agent-bridge-dev" ]] && SESSION_NAME="$CONFIG_SESSION"
  [[ "$PANE_COUNT" == 3 ]] && PANE_COUNT="$CONFIG_PANES"
  [[ "$IMPLEMENTER_RUNTIME" == opencode ]] && IMPLEMENTER_RUNTIME="$CONFIG_IMPLEMENTER_RUNTIME"
  [[ "$REVIEWER_RUNTIME" == opencode ]] && REVIEWER_RUNTIME="$CONFIG_REVIEWER_RUNTIME"
  [[ "$ORCHESTRATOR_RUNTIME" == codex ]] && ORCHESTRATOR_RUNTIME="$CONFIG_ORCHESTRATOR_RUNTIME"
  [[ "$ORCHESTRATOR_PANE" == 0 ]] && ORCHESTRATOR_PANE="$CONFIG_ORCHESTRATOR_PANE"
  [[ "$IMPLEMENTER_PANE" == 1 ]] && IMPLEMENTER_PANE="$CONFIG_IMPLEMENTER_PANE"
  [[ "$REVIEWER_PANE" == 2 ]] && REVIEWER_PANE="$CONFIG_REVIEWER_PANE"
  [[ "$IMPLEMENTER_ROLE" == implementation ]] && IMPLEMENTER_ROLE="$CONFIG_IMPLEMENTER_ROLE"
  [[ "$REVIEWER_ROLE" == review ]] && REVIEWER_ROLE="$CONFIG_REVIEWER_ROLE"
fi
command -v tmux >/dev/null 2>&1 || die "required command not installed: tmux. Run: agent-bridge doctor"
command -v python3 >/dev/null 2>&1 || die "required command not installed: python3. Run: agent-bridge doctor"
command -v node >/dev/null 2>&1 || die "required command not installed: node (Node.js 18+ required by tmux-bridge-mcp). Run: agent-bridge doctor"
command -v npx >/dev/null 2>&1 || die "required command not installed: npx (required by tmux-bridge-mcp). Run: agent-bridge doctor"
[[ "$ORCHESTRATOR_PANE" =~ ^[0-9]+$ && "$IMPLEMENTER_PANE" =~ ^[0-9]+$ && "$REVIEWER_PANE" =~ ^[0-9]+$ ]] || die "agent panes must be integers"
(( ORCHESTRATOR_PANE < PANE_COUNT && IMPLEMENTER_PANE < PANE_COUNT && REVIEWER_PANE < PANE_COUNT )) || die "agent pane is outside pane_count"
[[ "$ORCHESTRATOR_PANE" != "$IMPLEMENTER_PANE" && "$ORCHESTRATOR_PANE" != "$REVIEWER_PANE" && "$IMPLEMENTER_PANE" != "$REVIEWER_PANE" ]] || die "agent panes must be unique"
if [[ "$ORCHESTRATOR_RUNTIME" != none ]]; then
  runtime_cmd="$("$SCRIPT_DIR/runtime-adapter.sh" "$ORCHESTRATOR_RUNTIME")"
  command -v "$runtime_cmd" >/dev/null 2>&1 || die "runtime not installed: $ORCHESTRATOR_RUNTIME. Run: agent-bridge doctor"
fi
implementer_cmd="$("$SCRIPT_DIR/runtime-adapter.sh" "$IMPLEMENTER_RUNTIME")"
reviewer_cmd="$("$SCRIPT_DIR/runtime-adapter.sh" "$REVIEWER_RUNTIME")"
command -v "$implementer_cmd" >/dev/null 2>&1 || die "runtime not installed: $IMPLEMENTER_RUNTIME. Run: agent-bridge doctor"
command -v "$reviewer_cmd" >/dev/null 2>&1 || die "runtime not installed: $REVIEWER_RUNTIME. Run: agent-bridge doctor"
RUNTIME_DIR="$PROJECT_DIR/.ai-bridge"
mkdir -p "$RUNTIME_DIR/mailbox" "$RUNTIME_DIR/state"
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  echo "Session '$SESSION_NAME' already exists. Attach with: tmux attach -t $SESSION_NAME"
  exit 0
fi
tmux new-session -d -s "$SESSION_NAME" -c "$PROJECT_DIR"
tmux split-window -h -t "$SESSION_NAME:0" -c "$PROJECT_DIR"
tmux split-window -v -t "$SESSION_NAME:0.0" -c "$PROJECT_DIR"
for ((pane=3; pane<PANE_COUNT; pane++)); do tmux split-window -v -t "$SESSION_NAME:0.0" -c "$PROJECT_DIR"; done
tmux select-layout -t "$SESSION_NAME:0" tiled
tmux select-pane -t "$SESSION_NAME:0.$ORCHESTRATOR_PANE" -T orchestrator
tmux select-pane -t "$SESSION_NAME:0.$IMPLEMENTER_PANE" -T "$IMPLEMENTER_ROLE"
tmux select-pane -t "$SESSION_NAME:0.$REVIEWER_PANE" -T "$REVIEWER_ROLE"
if [[ "$ORCHESTRATOR_RUNTIME" != none ]]; then
  orchestrator_cmd="$("$SCRIPT_DIR/runtime-adapter.sh" "$ORCHESTRATOR_RUNTIME")"
  command -v "$orchestrator_cmd" >/dev/null 2>&1 || die "runtime not installed: $ORCHESTRATOR_RUNTIME"
  tmux send-keys -t "$SESSION_NAME:0.$ORCHESTRATOR_PANE" "$orchestrator_cmd" Enter
fi
tmux send-keys -t "$SESSION_NAME:0.$IMPLEMENTER_PANE" "$implementer_cmd" Enter
tmux send-keys -t "$SESSION_NAME:0.$REVIEWER_PANE" "$reviewer_cmd" Enter
SUPERVISOR_SCRIPT="$SCRIPT_DIR/supervisor.sh"
if [[ -x "$SUPERVISOR_SCRIPT" ]]; then
  "$SUPERVISOR_SCRIPT" --session "$SESSION_NAME" --project "$PROJECT_DIR" --implementer-pane "$IMPLEMENTER_PANE" --reviewer-pane "$REVIEWER_PANE" >"$RUNTIME_DIR/state/supervisor.log" 2>&1 &
  echo $! > "$RUNTIME_DIR/state/supervisor.pid"
fi
printf 'session_started %s project=%s\n' "$(date +%s)" "$PROJECT_DIR" >> "$RUNTIME_DIR/state/events.log"
echo "READY session=$SESSION_NAME project=$PROJECT_DIR panes=$PANE_COUNT orchestrator=$ORCHESTRATOR_RUNTIME implementer=$IMPLEMENTER_RUNTIME reviewer=$REVIEWER_RUNTIME"
echo "Attach with: tmux attach -t $SESSION_NAME"
if (( ATTACH )); then
  exec tmux attach -t "$SESSION_NAME"
fi
