#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
command -v tmux >/dev/null 2>&1 || { echo "tmux integration test skipped: tmux not installed"; exit 0; }
tmux list-sessions >/dev/null 2>&1 || { echo "tmux integration test skipped: tmux server unavailable"; exit 0; }
TMP_PROJECT="$(mktemp -d "${TMPDIR:-/tmp}/agent-bridge-integration.XXXXXX")"
SESSION="agent-bridge-test-$$"
cleanup() {
  "$ROOT/scripts/agent-bridge-stop.sh" --project "$TMP_PROJECT" --session "$SESSION" >/dev/null 2>&1 || true
  rm -rf "$TMP_PROJECT"
}
trap cleanup EXIT

"$ROOT/scripts/agent-bridge-install.sh" --project "$TMP_PROJECT" --copy-config >/dev/null
if find "$TMP_PROJECT/.ai-bridge" -type d -perm -007 -print -quit 2>/dev/null | grep -q .; then
  echo "runtime directory is accessible by group or others" >&2
  exit 1
fi
"$ROOT/scripts/agent-bridge.sh" --project "$TMP_PROJECT" --session "$SESSION" \
  --orchestrator-runtime none --implementer-runtime shell --reviewer-runtime shell --detach >/dev/null
sleep 1
status="$($ROOT/scripts/agent-bridge status --project "$TMP_PROJECT" --session "$SESSION")"
grep -q '^tmux=running$' <<<"$status"
grep -q '^supervisor=running ' <<<"$status"
"$ROOT/scripts/agent-bridge-logs.sh" --project "$TMP_PROJECT" --lines 5 >/dev/null
"$ROOT/scripts/agent-bridge-stop.sh" --project "$TMP_PROJECT" --session "$SESSION" >/dev/null
! tmux has-session -t "$SESSION" 2>/dev/null
echo "tmux integration test passed"
