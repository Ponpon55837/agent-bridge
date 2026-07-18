#!/usr/bin/env bash
set -euo pipefail
session="${1:-}"
[[ "$session" =~ ^[A-Za-z0-9_-]+$ ]] || { echo "Usage: $0 SESSION_NAME" >&2; exit 1; }
tmux has-session -t "$session" 2>/dev/null || { echo "session not found: $session" >&2; exit 1; }
if [[ -n "${TMUX:-}" ]]; then tmux switch-client -t "$session"; else exec tmux attach -t "$session"; fi
