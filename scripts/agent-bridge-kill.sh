#!/usr/bin/env bash
set -euo pipefail
session=""; force=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --session) session="${2:-}"; shift 2;;
    --force) force=1; shift;;
    *) echo "Usage: $0 --session NAME [--force]" >&2; exit 1;;
  esac
done
[[ "$session" =~ ^[A-Za-z0-9_-]+$ ]] || { echo "a valid --session NAME is required" >&2; exit 1; }
tmux has-session -t "$session" 2>/dev/null || { echo "session not found: $session" >&2; exit 1; }
if (( ! force )); then
  printf "Kill tmux session '%s'? [y/N] " "$session"; read -r answer
  [[ "$answer" == y || "$answer" == Y ]] || { echo "cancelled"; exit 0; }
fi
tmux kill-session -t "$session"
echo "KILLED session=$session"
