#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(pwd)"; FORCE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) PROJECT_DIR="$2"; shift 2;;
    --force) FORCE=1; shift;;
    *) echo "Usage: $0 [--project DIR] [--force]" >&2; exit 1;;
  esac
done
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
if (( ! FORCE )); then echo "Dry run. Re-run with --force to remove $PROJECT_DIR/.ai-bridge"; exit 0; fi
"$(dirname "$0")/agent-bridge-stop.sh" --project "$PROJECT_DIR"
rm -rf "$PROJECT_DIR/.ai-bridge"
gitignore="$PROJECT_DIR/.gitignore"
if [[ -f "$gitignore" ]]; then
  tmp="$gitignore.tmp.$$"
  awk 'BEGIN{drop=0} /^# agent-bridge:start$/{drop=1; next} /^# agent-bridge:end$/{drop=0; next} !drop{print}' "$gitignore" > "$tmp"
  mv -f "$tmp" "$gitignore"
fi
echo "UNINSTALLED runtime from $PROJECT_DIR"
