#!/usr/bin/env bash
set -euo pipefail
runtime="${1:-}"
case "$runtime" in
  codex) echo codex;;
  opencode) echo opencode;;
  claude) echo claude;;
  shell) echo "${SHELL:-bash}";;
  *) echo "unsupported runtime: $runtime" >&2; exit 1;;
esac
