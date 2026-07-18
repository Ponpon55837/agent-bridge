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
    marker="# agent-bridge path"
    add_path_entry() {
      local rc="$1"
      if ! grep -Fqx "$marker" "$rc" 2>/dev/null; then
        { [[ -s "$rc" ]] && printf '\n'; printf '%s\nexport PATH="%s:$PATH"\n' "$marker" "$BIN_DIR"; } >> "$rc"
      fi
    }
    if [[ -n "${BASH_VERSION:-}" ]]; then
      add_path_entry "$HOME/.bashrc"
      add_path_entry "$HOME/.bash_profile"
    elif [[ -n "${ZSH_VERSION:-}" ]]; then
      add_path_entry "$HOME/.zshrc"
    else
      shell_name="$(basename "${SHELL:-sh}")"
      case "$shell_name" in
        zsh) add_path_entry "$HOME/.zshrc" ;;
        bash) add_path_entry "$HOME/.bashrc"; add_path_entry "$HOME/.bash_profile" ;;
        *) add_path_entry "$HOME/.profile" ;;
      esac
    fi
    echo "已幫你設定完成。請關閉這個終端機，再開一個新的終端機。"
    echo "新的終端機開好後，直接輸入：agent-bridge doctor"
    ;;
esac
