#!/usr/bin/env bash
set -euo pipefail
old="${1:-}"; new="${2:-}"
[[ "$old" =~ ^[A-Za-z0-9_-]+$ && "$new" =~ ^[A-Za-z0-9_-]+$ ]] || { echo "Usage: $0 OLD_NAME NEW_NAME" >&2; exit 1; }
tmux has-session -t "$old" 2>/dev/null || { echo "session not found: $old" >&2; exit 1; }
tmux has-session -t "$new" 2>/dev/null && { echo "target session already exists: $new" >&2; exit 1; }
tmux rename-session -t "$old" "$new"
echo "RENAMED $old -> $new"
