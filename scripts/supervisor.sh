#!/usr/bin/env bash
set -euo pipefail
umask 077
SESSION_NAME="agent-bridge-dev"; PROJECT_DIR=""
PANE_COUNT=3; IMPLEMENTER_A_PANE=1; IMPLEMENTER_B_PANE=""; REVIEWER_PANE=""; ORCHESTRATOR_PANE=0; LEGACY_IMPLEMENTER_PANE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --session) [[ $# -ge 2 ]] || exit 1; SESSION_NAME="$2"; shift 2 ;;
    --project) [[ $# -ge 2 ]] || exit 1; PROJECT_DIR="$2"; shift 2 ;;
    --pane-count) [[ $# -ge 2 ]] || exit 1; PANE_COUNT="$2"; shift 2 ;;
    --implementer-a-pane) [[ $# -ge 2 ]] || exit 1; IMPLEMENTER_A_PANE="$2"; shift 2 ;;
    --implementer-b-pane) [[ $# -ge 2 ]] || exit 1; IMPLEMENTER_B_PANE="$2"; shift 2 ;;
    --implementer-pane) [[ $# -ge 2 ]] || exit 1; LEGACY_IMPLEMENTER_PANE="$2"; shift 2 ;;
    --reviewer-pane) [[ $# -ge 2 ]] || exit 1; REVIEWER_PANE="$2"; shift 2 ;;
    --orchestrator-pane) [[ $# -ge 2 ]] || exit 1; ORCHESTRATOR_PANE="$2"; shift 2 ;;
    -h|--help) echo "Usage: $0 [--session NAME] [--project DIR]"; exit 0 ;;
    *) exit 1 ;;
  esac
done
[[ "$SESSION_NAME" =~ ^[A-Za-z0-9_-]+$ ]] || { echo "invalid session" >&2; exit 1; }
[[ -z "$LEGACY_IMPLEMENTER_PANE" || "$IMPLEMENTER_A_PANE" == 1 ]] || { echo "implementer pane options conflict" >&2; exit 1; }
[[ -z "$LEGACY_IMPLEMENTER_PANE" ]] || IMPLEMENTER_A_PANE="$LEGACY_IMPLEMENTER_PANE"
[[ "$PANE_COUNT" =~ ^[234]$ ]] || { echo "pane-count must be 2, 3, or 4" >&2; exit 1; }
[[ "$ORCHESTRATOR_PANE" =~ ^[0-9]+$ && "$IMPLEMENTER_A_PANE" =~ ^[0-9]+$ ]] || { echo "invalid required agent pane" >&2; exit 1; }
case "$PANE_COUNT" in
  2) [[ -z "$IMPLEMENTER_B_PANE" && -z "$REVIEWER_PANE" ]] || { echo "invalid 2-pane configuration" >&2; exit 1; };;
  3) [[ -z "$IMPLEMENTER_B_PANE" ]] || { echo "invalid 3-pane configuration" >&2; exit 1; }; [[ -n "$REVIEWER_PANE" ]] || REVIEWER_PANE=2;;
  4) [[ "$IMPLEMENTER_B_PANE" =~ ^[0-9]+$ && "$REVIEWER_PANE" =~ ^[0-9]+$ ]] || { echo "invalid 4-pane configuration" >&2; exit 1; };;
esac
for pane in "$ORCHESTRATOR_PANE" "$IMPLEMENTER_A_PANE" "$IMPLEMENTER_B_PANE" "$REVIEWER_PANE"; do [[ -z "$pane" ]] || { (( pane < PANE_COUNT )) || exit 1; }; done
[[ -n "$PROJECT_DIR" ]] || PROJECT_DIR="$(pwd)"
IMPLEMENTER_PANE="$IMPLEMENTER_A_PANE"
PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || exit 1
RUNTIME_DIR="$PROJECT_DIR/.ai-bridge"; MAILBOX_DIR="$RUNTIME_DIR/mailbox"; STATE_DIR="$RUNTIME_DIR/state"
mkdir -p "$MAILBOX_DIR" "$STATE_DIR"; EVENTS_LOG="$STATE_DIR/events.log"; HEARTBEAT="$STATE_DIR/.supervisor-heartbeat"; WORKFLOW_STATE="$STATE_DIR/workflow.json"
cleanup_supervisor() { rm -f "$HEARTBEAT"; }
trap cleanup_supervisor EXIT
record_event() { printf '%s %s\n' "$(date +%s)" "$1" >> "$EVENTS_LOG"; }
write_mailbox() {
  local agent_id="$1" status="$2" content="$3" ts file tmp
  ts="$(date +%s)"; file="$MAILBOX_DIR/${agent_id}.${status}.${ts}.md"; tmp="$file.tmp.$$"
  printf '%s\n' "$content" > "$tmp" && mv -f "$tmp" "$file"; record_event "mailbox: wrote $file"
  write_handoff_metadata "$agent_id" "$status" "$ts" "$file"
  write_workflow_state "$agent_id" "$status" "$ts"
}
write_handoff_metadata() {
  local agent_id="$1" status="$2" ts="$3" mailbox_file="$4" file tmp
  file="$mailbox_file.json"; tmp="$file.tmp.$$"
  python3 -c 'import json,sys; print(json.dumps({"schema_version":1,"type":"agent_handoff","agent":sys.argv[1],"status":sys.argv[2],"timestamp":int(sys.argv[3]),"mailbox_file":sys.argv[4].split("/")[-1],"summary":None,"changed_files":[],"verification":None,"next_action":None}, ensure_ascii=False))' \
    "$agent_id" "$status" "$ts" "$mailbox_file" > "$tmp" && mv -f "$tmp" "$file"
  record_event "handoff: wrote $file"
}
write_workflow_state() {
  local agent_id="$1" status="$2" ts="$3" file tmp next_action
  file="$WORKFLOW_STATE"; tmp="$file.tmp.$$"
  case "$status" in
    ready_for_review) next_action="review";;
    review_complete) next_action="orchestrator_decision";;
    *) next_action="orchestrator_follow_up";;
  esac
  python3 - "$file" "$agent_id" "$status" "$ts" "$next_action" <<'PY' > "$tmp"
import json, sys
path, agent, status, timestamp, next_action = sys.argv[1:]
try:
    state = json.load(open(path, encoding="utf-8"))
except (OSError, ValueError):
    state = {"schema_version": 2, "agents": {}}
state["schema_version"] = 2
state.setdefault("agents", {})[agent] = {"status": status, "timestamp": int(timestamp)}
state["next_action"] = next_action
print(json.dumps(state, ensure_ascii=False))
PY
  mv -f "$tmp" "$file"
  record_event "workflow: agent=$agent_id status=$status next=$next_action"
}
notify_pane() {
  local pane="$1" message="$2"
  tmux send-keys -t "$SESSION_NAME:0.$pane" "$message" Enter
  record_event "handoff: pane=$pane message=$message"
}
valid_handoff() {
  local pane="$1"
  grep -qE '\[AGENT_BRIDGE STATUS=(IN_PROGRESS|READY_FOR_REVIEW|APPROVED|CHANGES_REQUESTED|BLOCKED|DONE)\]' <<<"$pane" || return 1
  grep -qE '(SUMMARY|FINDINGS)[[:space:]]*[:=]' <<<"$pane" || return 1
  grep -qE 'VERIFICATION[[:space:]]*[:=]' <<<"$pane" || return 1
  grep -qE 'NEXT_ACTION[[:space:]]*[:=]' <<<"$pane" || return 1
}
hash_text() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256
  elif command -v sha256sum >/dev/null 2>&1; then sha256sum
  else cksum
  fi
}
last_hash1=""; last_hash2=""; last_hash3=""; notified_hash1=""; notified_hash2=""; notified_hash3=""
record_event "supervisor_started session=$SESSION_NAME project=$PROJECT_DIR"
while tmux has-session -t "$SESSION_NAME" 2>/dev/null; do
  touch "$HEARTBEAT"
  pane1="$(tmux capture-pane -t "$SESSION_NAME:0.$IMPLEMENTER_PANE" -p -S -500 2>/dev/null || true)"
  pane2=""; [[ -z "$REVIEWER_PANE" ]] || pane2="$(tmux capture-pane -t "$SESSION_NAME:0.$REVIEWER_PANE" -p -S -500 2>/dev/null || true)"
  pane3=""; [[ -z "$IMPLEMENTER_B_PANE" ]] || pane3="$(tmux capture-pane -t "$SESSION_NAME:0.$IMPLEMENTER_B_PANE" -p -S -500 2>/dev/null || true)"
  hash1="$(printf '%s' "$pane1" | hash_text | cut -d' ' -f1)"; hash2="$(printf '%s' "$pane2" | hash_text | cut -d' ' -f1)"
  if [[ "$hash1" != "$last_hash1" ]] && { grep -qE '\[(opencode-1|agent-1) 完成通知\]' <<<"$pane1" || valid_handoff "$pane1"; }; then
    write_mailbox agent-1 ready_for_review "$pane1"
    if [[ "$hash1" != "$notified_hash1" ]]; then
      notify_pane "$REVIEWER_PANE" "HANDOFF from implementer: STATUS=READY_FOR_REVIEW. Implementation completed. Read the implementer pane, inspect changed files, run verification, then report STATUS=APPROVED or STATUS=CHANGES_REQUESTED to Codex."
      notified_hash1="$hash1"
    fi
  fi
  if [[ "$hash2" != "$last_hash2" ]] && { grep -qE '\[(opencode-2|agent-2) 審查通知\]' <<<"$pane2" || valid_handoff "$pane2"; }; then
    write_mailbox agent-2 review_complete "$pane2"
    if [[ "$hash2" != "$notified_hash2" ]]; then
      notify_pane "$ORCHESTRATOR_PANE" "HANDOFF from reviewer: STATUS=REVIEW_COMPLETE. Read the reviewer report and changed files. If APPROVED, integrate and verify; if CHANGES_REQUESTED, send the findings back to the implementer. Continue the workflow now."
      notified_hash2="$hash2"
    fi
  fi
  if [[ -n "$IMPLEMENTER_B_PANE" ]]; then
    hash3="$(printf '%s' "$pane3" | hash_text | cut -d' ' -f1)"
    if [[ "$hash3" != "$last_hash3" ]] && valid_handoff "$pane3"; then
      write_mailbox agent-3 ready_for_review "$pane3"
      if [[ "$hash3" != "$notified_hash3" ]]; then
        if [[ -n "$REVIEWER_PANE" ]]; then notify_pane "$REVIEWER_PANE" "HANDOFF from implementer-b: inspect its changed files and verification, then report APPROVED or CHANGES_REQUESTED to Codex."; else notify_pane "$ORCHESTRATOR_PANE" "HANDOFF from implementer-b: no reviewer is configured; inspect the mailbox and explicitly decide the next action."; fi
        notified_hash3="$hash3"
      fi
    fi
    last_hash3="$hash3"
  fi
  last_hash1="$hash1"; last_hash2="$hash2"; [[ "$PANE_COUNT" == 4 ]] && sleep 4 || sleep 3
done
record_event supervisor_stopped
