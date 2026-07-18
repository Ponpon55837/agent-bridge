#!/usr/bin/env bash
set -euo pipefail
umask 077
SESSION_NAME="agent-bridge-dev"; PROJECT_DIR=""
IMPLEMENTER_PANE=1; REVIEWER_PANE=2; ORCHESTRATOR_PANE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --session) [[ $# -ge 2 ]] || exit 1; SESSION_NAME="$2"; shift 2 ;;
    --project) [[ $# -ge 2 ]] || exit 1; PROJECT_DIR="$2"; shift 2 ;;
    --implementer-pane) [[ $# -ge 2 ]] || exit 1; IMPLEMENTER_PANE="$2"; shift 2 ;;
    --reviewer-pane) [[ $# -ge 2 ]] || exit 1; REVIEWER_PANE="$2"; shift 2 ;;
    --orchestrator-pane) [[ $# -ge 2 ]] || exit 1; ORCHESTRATOR_PANE="$2"; shift 2 ;;
    -h|--help) echo "Usage: $0 [--session NAME] [--project DIR]"; exit 0 ;;
    *) exit 1 ;;
  esac
done
[[ "$SESSION_NAME" =~ ^[A-Za-z0-9_-]+$ ]] || { echo "invalid session" >&2; exit 1; }
[[ "$ORCHESTRATOR_PANE" =~ ^[0-9]+$ && "$IMPLEMENTER_PANE" =~ ^[0-9]+$ && "$REVIEWER_PANE" =~ ^[0-9]+$ ]] || { echo "invalid agent pane" >&2; exit 1; }
[[ -n "$PROJECT_DIR" ]] || PROJECT_DIR="$(pwd)"
PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || exit 1
RUNTIME_DIR="$PROJECT_DIR/.ai-bridge"; MAILBOX_DIR="$RUNTIME_DIR/mailbox"; STATE_DIR="$RUNTIME_DIR/state"
mkdir -p "$MAILBOX_DIR" "$STATE_DIR"; EVENTS_LOG="$STATE_DIR/events.log"; HEARTBEAT="$STATE_DIR/.supervisor-heartbeat"
cleanup_supervisor() { rm -f "$HEARTBEAT"; }
trap cleanup_supervisor EXIT
record_event() { printf '%s %s\n' "$(date +%s)" "$1" >> "$EVENTS_LOG"; }
write_mailbox() {
  local agent_id="$1" status="$2" content="$3" ts file tmp
  ts="$(date +%s)"; file="$MAILBOX_DIR/${agent_id}.${status}.${ts}.md"; tmp="$file.tmp.$$"
  printf '%s\n' "$content" > "$tmp" && mv -f "$tmp" "$file"; record_event "mailbox: wrote $file"
  write_handoff_metadata "$agent_id" "$status" "$ts" "$file"
}
write_handoff_metadata() {
  local agent_id="$1" status="$2" ts="$3" mailbox_file="$4" file tmp
  file="$mailbox_file.json"; tmp="$file.tmp.$$"
  python3 -c 'import json,sys; print(json.dumps({"agent":sys.argv[1],"status":sys.argv[2],"timestamp":int(sys.argv[3]),"mailbox_file":sys.argv[4]}, ensure_ascii=False))' \
    "$agent_id" "$status" "$ts" "$mailbox_file" > "$tmp" && mv -f "$tmp" "$file"
  record_event "handoff: wrote $file"
}
notify_pane() {
  local pane="$1" message="$2"
  tmux send-keys -t "$SESSION_NAME:0.$pane" "$message" Enter
  record_event "handoff: pane=$pane message=$message"
}
hash_text() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256
  elif command -v sha256sum >/dev/null 2>&1; then sha256sum
  else cksum
  fi
}
last_hash1=""; last_hash2=""; notified_hash1=""; notified_hash2=""
record_event "supervisor_started session=$SESSION_NAME project=$PROJECT_DIR"
while tmux has-session -t "$SESSION_NAME" 2>/dev/null; do
  touch "$HEARTBEAT"
  pane1="$(tmux capture-pane -t "$SESSION_NAME:0.$IMPLEMENTER_PANE" -p -S -500 2>/dev/null || true)"
  pane2="$(tmux capture-pane -t "$SESSION_NAME:0.$REVIEWER_PANE" -p -S -500 2>/dev/null || true)"
  hash1="$(printf '%s' "$pane1" | hash_text | cut -d' ' -f1)"; hash2="$(printf '%s' "$pane2" | hash_text | cut -d' ' -f1)"
  if [[ "$hash1" != "$last_hash1" ]] && grep -qE '\[(opencode-1|agent-1) 完成通知\]' <<<"$pane1"; then
    write_mailbox agent-1 done "$pane1"
    if [[ "$hash1" != "$notified_hash1" ]]; then
      notify_pane "$REVIEWER_PANE" "HANDOFF from implementer: STATUS=READY_FOR_REVIEW. Implementation completed. Read the implementer pane, inspect changed files, run verification, then report STATUS=APPROVED or STATUS=CHANGES_REQUESTED to Codex."
      notified_hash1="$hash1"
    fi
  fi
  if [[ "$hash2" != "$last_hash2" ]] && grep -qE '\[(opencode-2|agent-2) 審查通知\]' <<<"$pane2"; then
    write_mailbox agent-2 review "$pane2"
    if [[ "$hash2" != "$notified_hash2" ]]; then
      notify_pane "$ORCHESTRATOR_PANE" "HANDOFF from reviewer: STATUS=REVIEW_COMPLETE. Read the reviewer report and changed files. If APPROVED, integrate and verify; if CHANGES_REQUESTED, send the findings back to the implementer. Continue the workflow now."
      notified_hash2="$hash2"
    fi
  fi
  last_hash1="$hash1"; last_hash2="$hash2"; sleep 3
done
record_event supervisor_stopped
