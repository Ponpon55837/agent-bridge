#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(pwd)"; LINES=80; AGENT=""; FOLLOW=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) [[ $# -ge 2 ]] || { echo "--project requires a value" >&2; exit 1; }; PROJECT_DIR="$2"; shift 2 ;;
    --lines) [[ $# -ge 2 && "$2" =~ ^[1-9][0-9]*$ ]] || { echo "--lines requires a positive integer" >&2; exit 1; }; LINES="$2"; shift 2 ;;
    --agent) [[ $# -ge 2 && "$2" =~ ^[A-Za-z0-9_-]+$ ]] || { echo "--agent requires a valid agent id" >&2; exit 1; }; AGENT="$2"; shift 2 ;;
    --follow) FOLLOW=1; shift ;;
    *) echo "Usage: $0 [--project DIR] [--lines N]" >&2; exit 1 ;;
  esac
done
PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || { echo "project not found" >&2; exit 1; }
RUNTIME_DIR="$PROJECT_DIR/.ai-bridge"; STATE_DIR="$RUNTIME_DIR/state"; MAILBOX_DIR="$RUNTIME_DIR/mailbox"
[[ -d "$RUNTIME_DIR" ]] || { echo "runtime not found: $RUNTIME_DIR" >&2; exit 1; }
echo "project=$PROJECT_DIR"
if (( FOLLOW )); then
  [[ -f "$STATE_DIR/supervisor.log" ]] || { echo "supervisor log not found" >&2; exit 1; }
  exec tail -f "$STATE_DIR/supervisor.log"
fi
for file in "$STATE_DIR/supervisor.log" "$STATE_DIR/events.log"; do
  echo
  echo "--- $file ---"
  if [[ -f "$file" ]]; then tail -n "$LINES" "$file"; else echo "not found"; fi
done
echo
echo "--- recent handoffs ---"
if [[ -d "$MAILBOX_DIR" ]]; then
  if [[ -n "$AGENT" ]]; then
    find "$MAILBOX_DIR" -type f -name "$AGENT.*.json" -print 2>/dev/null | sort | tail -n "$LINES"
  else
    find "$MAILBOX_DIR" -type f -name '*.json' -print 2>/dev/null | sort | tail -n "$LINES"
  fi
else
  echo "mailbox not found"
fi
