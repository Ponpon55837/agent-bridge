#!/usr/bin/env bash
set -euo pipefail
umask 077
SESSION_NAME="agent-bridge-dev"
PROJECT_DIR=""
CONFIG_FILE=""
IMPLEMENTER_A_PANE=1
IMPLEMENTER_B_PANE=""
REVIEWER_PANE=""
ORCHESTRATOR_PANE=0
IMPLEMENTER_ROLE="implementation"
REVIEWER_ROLE="review"
PANE_COUNT=3
PANE_COUNT_EXPLICIT=0
IMPLEMENTER_RUNTIME="opencode"
IMPLEMENTER_B_RUNTIME="opencode"
REVIEWER_RUNTIME="opencode"
ORCHESTRATOR_RUNTIME="codex"
PRESET=""
ATTACH=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRIDGE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
die() { echo "agent-bridge: $*" >&2; exit 1; }
while [[ $# -gt 0 ]]; do
  case "$1" in
    --session) [[ $# -ge 2 ]] || die "--session requires a value"; SESSION_NAME="$2"; shift 2 ;;
    --project) [[ $# -ge 2 ]] || die "--project requires a value"; PROJECT_DIR="$2"; shift 2 ;;
    --config) [[ $# -ge 2 ]] || die "--config requires a value"; CONFIG_FILE="$2"; shift 2 ;;
    --panes) [[ $# -ge 2 ]] || die "--panes requires a value"; PANE_COUNT="$2"; PANE_COUNT_EXPLICIT=1; shift 2 ;;
    --implementer-runtime) [[ $# -ge 2 ]] || die "--implementer-runtime requires a value"; IMPLEMENTER_RUNTIME="$2"; shift 2 ;;
    --reviewer-runtime) [[ $# -ge 2 ]] || die "--reviewer-runtime requires a value"; REVIEWER_RUNTIME="$2"; shift 2 ;;
    --orchestrator-runtime) [[ $# -ge 2 ]] || die "--orchestrator-runtime requires a value"; ORCHESTRATOR_RUNTIME="$2"; shift 2 ;;
    --preset) [[ $# -ge 2 ]] || die "--preset requires a value"; PRESET="$2"; shift 2 ;;
    --detach) ATTACH=0; shift ;;
    --attach) ATTACH=1; shift ;;
    -h|--help) echo "Usage: $0 [--session NAME] [--project DIR]"; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done
[[ "$SESSION_NAME" =~ ^[A-Za-z0-9_-]+$ ]] || die "invalid session name"
[[ "$PANE_COUNT" =~ ^[234]$ ]] || die "panes must be 2, 3, or 4"
[[ -n "$PROJECT_DIR" ]] || PROJECT_DIR="$BRIDGE_ROOT"
PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || die "project directory does not exist"
[[ -n "$CONFIG_FILE" ]] || [[ ! -f "$PROJECT_DIR/.ai-bridge.yaml" ]] || CONFIG_FILE="$PROJECT_DIR/.ai-bridge.yaml"
if [[ -n "$CONFIG_FILE" ]]; then
  [[ -f "$CONFIG_FILE" ]] || die "config file does not exist: $CONFIG_FILE"
  eval "$(python3 "$SCRIPT_DIR/config-loader.py" "$CONFIG_FILE")"
  [[ "$SESSION_NAME" == "agent-bridge-dev" ]] && SESSION_NAME="$CONFIG_SESSION"
  (( PANE_COUNT_EXPLICIT )) || PANE_COUNT="$CONFIG_PANES"
  [[ "$IMPLEMENTER_RUNTIME" == opencode ]] && IMPLEMENTER_RUNTIME="$CONFIG_IMPLEMENTER_RUNTIME"
  [[ "$IMPLEMENTER_B_RUNTIME" == opencode ]] && IMPLEMENTER_B_RUNTIME="$CONFIG_IMPLEMENTER_B_RUNTIME"
  [[ "$REVIEWER_RUNTIME" == opencode ]] && REVIEWER_RUNTIME="$CONFIG_REVIEWER_RUNTIME"
  [[ "$ORCHESTRATOR_RUNTIME" == codex ]] && ORCHESTRATOR_RUNTIME="$CONFIG_ORCHESTRATOR_RUNTIME"
  [[ "$ORCHESTRATOR_PANE" == 0 ]] && ORCHESTRATOR_PANE="$CONFIG_ORCHESTRATOR_PANE"
  [[ "$IMPLEMENTER_A_PANE" == 1 ]] && IMPLEMENTER_A_PANE="$CONFIG_IMPLEMENTER_A_PANE"
  IMPLEMENTER_B_PANE="$CONFIG_IMPLEMENTER_B_PANE"
  REVIEWER_PANE="$CONFIG_REVIEWER_PANE"
  [[ "$IMPLEMENTER_ROLE" == implementation ]] && IMPLEMENTER_ROLE="$CONFIG_IMPLEMENTER_ROLE"
  [[ "$REVIEWER_ROLE" == review ]] && REVIEWER_ROLE="$CONFIG_REVIEWER_ROLE"
fi
case "$PRESET" in
  "") ;;
  standard) ORCHESTRATOR_RUNTIME=codex; IMPLEMENTER_RUNTIME=opencode; REVIEWER_RUNTIME=opencode ;;
  review) ORCHESTRATOR_RUNTIME=codex; IMPLEMENTER_RUNTIME=opencode; REVIEWER_RUNTIME=claude ;;
  *) die "unsupported preset: $PRESET (use standard or review)" ;;
esac
command -v tmux >/dev/null 2>&1 || die "required command not installed: tmux. Run: agent-bridge doctor"
command -v python3 >/dev/null 2>&1 || die "required command not installed: python3. Run: agent-bridge doctor"
command -v node >/dev/null 2>&1 || die "required command not installed: node (Node.js 18+ required by tmux-bridge-mcp). Run: agent-bridge doctor"
command -v npx >/dev/null 2>&1 || die "required command not installed: npx (required by tmux-bridge-mcp). Run: agent-bridge doctor"
[[ "$PANE_COUNT" =~ ^[234]$ ]] || die "panes must be 2, 3, or 4"
IMPLEMENTER_A_PANE=1
IMPLEMENTER_B_PANE=""
REVIEWER_PANE=""
case "$PANE_COUNT" in
  3) REVIEWER_PANE=2 ;;
  4) IMPLEMENTER_B_PANE=2; REVIEWER_PANE=3 ;;
esac
[[ "$ORCHESTRATOR_PANE" =~ ^[0-9]+$ && "$IMPLEMENTER_A_PANE" =~ ^[0-9]+$ ]] || die "agent panes must be integers"
(( ORCHESTRATOR_PANE < PANE_COUNT && IMPLEMENTER_A_PANE < PANE_COUNT )) || die "agent pane is outside pane_count"
if [[ "$PANE_COUNT" == 4 ]]; then [[ "$IMPLEMENTER_B_PANE" != "$ORCHESTRATOR_PANE" && "$IMPLEMENTER_B_PANE" != "$IMPLEMENTER_A_PANE" ]] || die "agent panes must be unique"; fi
if [[ -n "$REVIEWER_PANE" ]]; then [[ "$REVIEWER_PANE" != "$ORCHESTRATOR_PANE" && "$REVIEWER_PANE" != "$IMPLEMENTER_A_PANE" && "$REVIEWER_PANE" != "$IMPLEMENTER_B_PANE" ]] || die "agent panes must be unique"; fi
if [[ "$ORCHESTRATOR_RUNTIME" != none ]]; then
  runtime_cmd="$("$SCRIPT_DIR/runtime-adapter.sh" "$ORCHESTRATOR_RUNTIME")"
  command -v "$runtime_cmd" >/dev/null 2>&1 || die "runtime not installed: $ORCHESTRATOR_RUNTIME. Run: agent-bridge doctor"
fi
implementer_cmd="$("$SCRIPT_DIR/runtime-adapter.sh" "$IMPLEMENTER_RUNTIME")"
implementer_b_cmd="$("$SCRIPT_DIR/runtime-adapter.sh" "$IMPLEMENTER_B_RUNTIME")"
reviewer_cmd="$("$SCRIPT_DIR/runtime-adapter.sh" "$REVIEWER_RUNTIME")"
command -v "$implementer_cmd" >/dev/null 2>&1 || die "runtime not installed: $IMPLEMENTER_RUNTIME. Run: agent-bridge doctor"
if [[ "$PANE_COUNT" == 4 ]]; then command -v "$implementer_b_cmd" >/dev/null 2>&1 || die "runtime not installed: $IMPLEMENTER_B_RUNTIME. Run: agent-bridge doctor"; fi
if [[ "$PANE_COUNT" != 2 ]]; then command -v "$reviewer_cmd" >/dev/null 2>&1 || die "runtime not installed: $REVIEWER_RUNTIME. Run: agent-bridge doctor"; fi
RUNTIME_DIR="$PROJECT_DIR/.ai-bridge"
mkdir -p "$RUNTIME_DIR/mailbox" "$RUNTIME_DIR/state"
created_session=0
cleanup_failed_start() {
  if (( created_session )); then
    tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
  fi
}
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  echo "Session '$SESSION_NAME' already exists."
  echo "Attach with: tmux attach -t $SESSION_NAME"
  if (( ATTACH )); then
    if [[ -n "$TMUX" ]]; then
      exec tmux switch-client -t "$SESSION_NAME"
    fi
    exec tmux attach -t "$SESSION_NAME"
  fi
  exit 0
fi
tmux new-session -d -s "$SESSION_NAME" -c "$PROJECT_DIR"
created_session=1
trap cleanup_failed_start EXIT
tmux split-window -h -t "$SESSION_NAME:0" -c "$PROJECT_DIR"
if [[ "$PANE_COUNT" != 2 ]]; then
  tmux split-window -v -t "$SESSION_NAME:0.0" -c "$PROJECT_DIR"
fi
if [[ "$PANE_COUNT" == 4 ]]; then
  tmux split-window -v -t "$SESSION_NAME:0.1" -c "$PROJECT_DIR"
fi
if [[ "$PANE_COUNT" == 2 ]]; then
  tmux select-layout -t "$SESSION_NAME:0" even-horizontal
else
  tmux select-layout -t "$SESSION_NAME:0" tiled
fi
tmux select-pane -t "$SESSION_NAME:0.$ORCHESTRATOR_PANE" -T orchestrator
tmux select-pane -t "$SESSION_NAME:0.$IMPLEMENTER_A_PANE" -T "$IMPLEMENTER_ROLE-a"
if [[ -n "$IMPLEMENTER_B_PANE" ]]; then tmux select-pane -t "$SESSION_NAME:0.$IMPLEMENTER_B_PANE" -T "$IMPLEMENTER_ROLE-b"; fi
if [[ -n "$REVIEWER_PANE" ]]; then tmux select-pane -t "$SESSION_NAME:0.$REVIEWER_PANE" -T "$REVIEWER_ROLE"; fi
SECURITY_NOTICE='安全要求：不得將 API token、密碼、私鑰、完整環境變數或其他敏感認證資訊寫入 mailbox、log、handoff 或訊息內容。若畫面中出現敏感資訊，請立即遮蔽且不要轉傳。'
ORCHESTRATOR_PROTOCOL='總控協定：你負責規劃、派工、追蹤與推進，不可只等待訊息。每個任務先建立明確步驟、驗收條件與負責 pane，再派工；收到回報後逐項核對，若缺少 STATUS、驗證結果或下一步，立即要求補報。流程狀態只能是 PLANNED、ASSIGNED、IN_PROGRESS、READY_FOR_REVIEW、APPROVED、CHANGES_REQUESTED、BLOCKED、DONE。'
IMPLEMENTER_PROTOCOL='執行協定：只執行總控明確派發的任務；開始時回報 [AGENT_BRIDGE STATUS=IN_PROGRESS]，完成時回報 [AGENT_BRIDGE STATUS=READY_FOR_REVIEW]，並包含 SUMMARY、CHANGED_FILES、VERIFICATION、BLOCKERS、NEXT_ACTION；遇到阻塞立即回報 BLOCKED，不得靜默等待或宣稱未驗證的完成。'
REVIEWER_PROTOCOL='審查協定：收到 READY_FOR_REVIEW 後才開始審查；完成時回報 [AGENT_BRIDGE STATUS=APPROVED] 或 [AGENT_BRIDGE STATUS=CHANGES_REQUESTED]，並包含 FINDINGS、VERIFICATION、NEXT_ACTION；沒有看到完整變更與驗證證據時不得回報 APPROVED。'
if [[ "$ORCHESTRATOR_RUNTIME" != none ]]; then
  orchestrator_cmd="$("$SCRIPT_DIR/runtime-adapter.sh" "$ORCHESTRATOR_RUNTIME")"
  command -v "$orchestrator_cmd" >/dev/null 2>&1 || die "runtime not installed: $ORCHESTRATOR_RUNTIME"
  tmux send-keys -t "$SESSION_NAME:0.$ORCHESTRATOR_PANE" "$orchestrator_cmd" Enter
  tmux send-keys -t "$SESSION_NAME:0.$ORCHESTRATOR_PANE" "$SECURITY_NOTICE" Enter
  tmux send-keys -t "$SESSION_NAME:0.$ORCHESTRATOR_PANE" "$ORCHESTRATOR_PROTOCOL" Enter
fi
send_agent() { local pane="$1" command="$2" security="$3" protocol="$4"; tmux send-keys -t "$SESSION_NAME:0.$pane" "$command" Enter; tmux send-keys -t "$SESSION_NAME:0.$pane" "$security" Enter; tmux send-keys -t "$SESSION_NAME:0.$pane" "$protocol" Enter; }
IMPLEMENTER_A_PROTOCOL="$IMPLEMENTER_PROTOCOL 你的身份是 implementer-a。收到任務後必須立即回報 IN_PROGRESS，完成後回報 READY_FOR_REVIEW；若無法繼續必須回報 BLOCKED，不得靜默等待。"
IMPLEMENTER_B_PROTOCOL="$IMPLEMENTER_PROTOCOL 你的身份是 implementer-b。先確認總控派工內容，再回報 IN_PROGRESS、READY_FOR_REVIEW 或 BLOCKED；不得假設 implementer-a 的任務已完成。"
REVIEWER_PROTOCOL="$REVIEWER_PROTOCOL 審查完成後必須明確回報 APPROVED 或 CHANGES_REQUESTED；若缺少變更或驗證證據，必須要求補充，不得只等待。"
send_agent "$IMPLEMENTER_A_PANE" "$implementer_cmd" "$SECURITY_NOTICE" "$IMPLEMENTER_A_PROTOCOL"
if [[ -n "$IMPLEMENTER_B_PANE" ]]; then send_agent "$IMPLEMENTER_B_PANE" "$implementer_b_cmd" "$SECURITY_NOTICE" "$IMPLEMENTER_B_PROTOCOL"; fi
if [[ -n "$REVIEWER_PANE" ]]; then send_agent "$REVIEWER_PANE" "$reviewer_cmd" "$SECURITY_NOTICE" "$REVIEWER_PROTOCOL"; fi
SUPERVISOR_SCRIPT="$SCRIPT_DIR/supervisor.sh"
if [[ -x "$SUPERVISOR_SCRIPT" ]]; then
  supervisor_args=(--session "$SESSION_NAME" --project "$PROJECT_DIR" --pane-count "$PANE_COUNT" --orchestrator-pane "$ORCHESTRATOR_PANE" --implementer-a-pane "$IMPLEMENTER_A_PANE")
  [[ -n "$IMPLEMENTER_B_PANE" ]] && supervisor_args+=(--implementer-b-pane "$IMPLEMENTER_B_PANE")
  [[ -n "$REVIEWER_PANE" ]] && supervisor_args+=(--reviewer-pane "$REVIEWER_PANE")
  "$SUPERVISOR_SCRIPT" "${supervisor_args[@]}" >"$RUNTIME_DIR/state/supervisor.log" 2>&1 &
  echo $! > "$RUNTIME_DIR/state/supervisor.pid"
fi
printf 'session_started %s project=%s\n' "$(date +%s)" "$PROJECT_DIR" >> "$RUNTIME_DIR/state/events.log"
echo "READY session=$SESSION_NAME project=$PROJECT_DIR panes=$PANE_COUNT orchestrator=$ORCHESTRATOR_RUNTIME implementer_a=$IMPLEMENTER_RUNTIME implementer_b=$IMPLEMENTER_B_RUNTIME reviewer=$REVIEWER_RUNTIME"
echo "Attach with: tmux attach -t $SESSION_NAME"
if (( ATTACH )); then
  trap - EXIT
  exec tmux attach -t "$SESSION_NAME"
fi
trap - EXIT
