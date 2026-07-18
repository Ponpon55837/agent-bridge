# Agent Bridge

Agent Bridge 是可導入多個專案的 tmux 多代理工作流。它建立三個 pane：

跨 pane 溝通使用 [tmux-bridge-mcp](https://github.com/howardpen9/tmux-bridge-mcp)。Agent Bridge 負責建立 pane；tmux-bridge-mcp 負責讓 Codex、Claude Code、OpenCode 等 MCP client 讀取與傳送訊息。兩者缺一不可。

| Pane | 角色 | 預設 runtime |
| --- | --- | --- |
| 0 | orchestrator | Codex |
| 1 | implementer | OpenCode |
| 2 | reviewer | Claude |

## 快速開始

### 安裝插件（只做一次）

~~~bash
git clone <agent-bridge-repository>
cd agent-bridge
./install.sh
agent-bridge doctor
~~~

安裝器會把 agent-bridge 放到 ~/.local/bin。若目前 shell 找不到它，重新開啟終端機，或依安裝器提示重新載入 shell 設定。

### 安裝跨 pane 通訊

tmux-bridge-mcp 需要 Node.js 18+ 與 npx：

~~~bash
npx -y tmux-bridge-mcp setup
npx -y tmux-bridge-mcp --help
~~~

setup 會替支援的 agent 建立 MCP 設定。完成後重新啟動 agent CLI；若使用自訂 MCP 設定，確認每個 agent 都包含 tmux-bridge server：

~~~json
{
  "mcpServers": {
    "tmux-bridge": {
      "command": "npx",
      "args": ["-y", "tmux-bridge-mcp"]
    }
  }
}
~~~

Agent Bridge 不會在啟動失敗時偷偷下載或安裝 MCP server。可用 agent-bridge doctor 檢查 node、npx 與 tmux；MCP 設定仍需由使用者確認。

### 初始化目標專案（每個專案一次）

~~~bash
cd /path/to/your-project
agent-bridge init
agent-bridge validate
~~~

init 會建立 .ai-bridge.yaml、runtime 目錄與必要的 .gitignore 區塊。插件已安裝不代表專案已初始化；validate 是啟動前的必要檢查。跨 pane 溝通另外需要先完成 tmux-bridge-mcp 設定。

### 啟動

~~~bash
agent-bridge up
~~~

啟動前會檢查專案、設定、tmux、python3 與設定中使用的 runtime。檢查失敗會停止，不會偷偷改用手動 tmux。

互動式終端會自動 attach；non-TTY 環境則會印出 session 名稱與 attach 指令：

~~~text
READY session=... panes=3 ...
Attach with: tmux attach -t <session>
~~~

未初始化時會明確顯示根因與修復命令：

~~~text
agent-bridge is not initialized for this project.
Missing: .ai-bridge.yaml
Run: agent-bridge init
~~~

## 日常操作

~~~bash
agent-bridge status
agent-bridge sessions
agent-bridge switch <session-name>
agent-bridge up
agent-bridge down
agent-bridge doctor
~~~

既有 session 會被重用，不會重複建立 pane。若狀態不正確，先執行 down，再重新 up。

## 多專案

~~~bash
agent-bridge up --project /projects/lucky50 --session lucky50-ai
agent-bridge up --project /projects/shop --session shop-ai
tmux attach -t lucky50-ai
~~~

## 設定 runtime 與 pane

修改目標專案的 .ai-bridge.yaml，或在啟動時覆寫：

~~~bash
agent-bridge up \
  --implementer-runtime opencode \
  --reviewer-runtime claude \
  --panes 4
~~~

支援 runtime：codex、opencode、claude、shell。修改 pane 數量或角色後，先停止既有 session；設定不會自動重建現有 pane。

~~~text
.ai-bridge.yaml       # 共用設定，可提交
.ai-bridge/            # mailbox、PID、log、事件；不提交
.ai-bridge.local.yaml  # 個人覆寫
~~~

更新設定範例前會先備份現有設定：

~~~bash
agent-bridge init --refresh-config
~~~

## 移除專案導入

~~~bash
agent-bridge uninstall --project /path/to/your-project
agent-bridge uninstall --project /path/to/your-project --force
~~~

移除會停止該 workflow、刪除 .ai-bridge/ 與插件加入的 .gitignore 區塊，不會刪除專案原始碼、Git 資料或其他 tmux session。

## 疑難排解

~~~bash
agent-bridge validate --project /path/to/your-project
agent-bridge doctor
agent-bridge status --project /path/to/your-project
~~~

- 缺少設定：執行 agent-bridge init --project /path/to/your-project
- 缺少 tmux 或 python3：安裝後重新執行 agent-bridge doctor
- node 或 npx 不存在：安裝 Node.js 18+
- MCP 工具不存在或 agent 沒有工具：執行 npx -y tmux-bridge-mcp setup，然後重啟 agent CLI
- runtime 未安裝：安裝設定指定的 CLI，或改用已安裝的 runtime
- session 已存在：執行 agent-bridge switch <session-name>

## 開發與文件

~~~bash
./scripts/agent-bridge validate
./tests/smoke.sh
~~~

- [快速開始](docs/QUICKSTART.md)
- [安裝與移除](docs/INSTALL.md)
- [設定規範](docs/CONFIGURATION.md)
- [Session 管理](docs/SESSIONS.md)
- [開發規範](docs/DEVELOPMENT.md)
- [Roadmap](ROADMAP.md)
