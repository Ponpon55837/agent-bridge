#!/usr/bin/env bash
set -euo pipefail
current="$(tmux display-message -p '#S' 2>/dev/null || true)"
printf '%-24s %-12s %-8s %s\n' SESSION STATUS PANES CURRENT
while IFS= read -r name; do
  [[ -n "$name" ]] || continue
  panes="$(tmux list-panes -t "$name" -F '#{pane_index}' 2>/dev/null | wc -l | tr -d ' ')"
  marker=""; [[ "$name" == "$current" ]] && marker='*'
  printf '%-24s %-12s %-8s %s\n' "$name" running "$panes" "$marker"
done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)
