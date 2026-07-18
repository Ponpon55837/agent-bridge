#!/usr/bin/env bash
set -euo pipefail
umask 077
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${AGENT_BRIDGE_BIN_DIR:-$HOME/.local/bin}"
mkdir -p "$BIN_DIR"
ln -sfn "$ROOT/scripts/agent-bridge" "$BIN_DIR/agent-bridge"
echo "已安裝 agent-bridge：$BIN_DIR/agent-bridge"
case ":${PATH}:" in
  *":$BIN_DIR:"*) echo "現在可以直接使用：agent-bridge doctor" ;;
  *)
    echo "請將以下路徑加入 shell PATH："
    echo "  export PATH=\"$BIN_DIR:\$PATH\""
    echo "加入後重新開啟終端機，再執行：agent-bridge doctor"
    ;;
esac
