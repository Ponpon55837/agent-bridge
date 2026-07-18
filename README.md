# Agent Bridge

Agent Bridge 是可導入多個專案的 tmux 多代理工作流。它建立三個 pane：

跨 pane 溝通使用 [tmux-bridge-mcp](https://github.com/howardpen9/tmux-bridge-mcp)。Agent Bridge 負責建立 pane；tmux-bridge-mcp 負責讓 Codex、Claude Code、OpenCode 等 MCP client 讀取與傳送訊息。兩者缺一不可。

| Pane | 角色 | 預設 runtime |
| --- | --- | --- |
| 0 | orchestrator | Codex |
| 1 | implementer | OpenCode |
| 2 | reviewer | Claude |

## 快速開始：只需要 setup 一次、up 一次

## 必要環境

Agent Bridge 啟動前需要以下工具：

| 工具 | 用途 |
| --- | --- |
| tmux | 建立與管理多個 agent pane |
| Python 3 | 解析 .ai-bridge.yaml 與載入設定 |
| Node.js 18+ / npx | 執行 tmux-bridge-mcp |
| Codex、OpenCode、Claude 等 CLI | 執行各個 agent runtime |

macOS 可以使用：

~~~bash
brew install tmux python node
~~~

Ubuntu/Debian 可以使用：

~~~bash
sudo apt update
sudo apt install tmux python3 nodejs npm
~~~

### Windows 支援方式

Windows 可以使用 Agent Bridge，但必須在能執行 Bash 腳本與 tmux 的 Unix 相容環境中。Windows 原生 PowerShell/CMD 不能直接執行本插件的 Bash scripts。

| 環境 | 支援程度 | 建議 |
| --- | --- | --- |
| WSL2 Ubuntu | 完整、最穩定 | 推薦 |
| MSYS2 | 可用，需自行確認 tmux 與 CLI PATH | 進階使用 |
| Cygwin | 可用，需自行確認 tmux 與 CLI PATH | 進階使用 |
| Git Bash | 不保證 tmux 相容性 | 不推薦 |
| PowerShell / CMD | 不支援目前 Bash 啟動腳本 | 不可直接使用 |

最推薦的安裝方式是 WSL2 Ubuntu：

~~~powershell
wsl --install -d Ubuntu
~~~

重新啟動 Windows 後，在 Ubuntu/WSL 終端執行：

~~~bash
sudo apt update
sudo apt install tmux python3 nodejs npm
~~~

然後在 WSL 的專案路徑內安裝 Agent Bridge。Agent Bridge、tmux、Python、Node.js 與所有 agent CLI 必須安裝在同一個 WSL 環境中；Windows 主機上的 tmux 或 CLI 不會自動被使用。

確認環境：

~~~bash
tmux -V
python3 --version
node --version
npx --version
~~~

agent-bridge doctor 與 agent-bridge validate 也會在啟動前檢查 tmux、Python、Node.js 和 npx。缺少任何必要工具時，session 不會建立。

### 安裝插件（只做一次）

~~~bash
git clone <agent-bridge-repository>
cd agent-bridge
./install.sh
agent-bridge doctor
~~~

安裝器會把 agent-bridge 放到 ~/.local/bin。若目前 shell 找不到它，重新開啟終端機，或依安裝器提示重新載入 shell 設定。

### 安裝跨 pane 通訊

tmux-bridge-mcp 需要 Node.js 18+ 與 npx。為降低 npm 供應鏈風險，請使用已審查並固定的版本，不要直接使用未鎖定版本：

~~~bash
npx -y tmux-bridge-mcp@<reviewed-version> setup
npx -y tmux-bridge-mcp@<reviewed-version> --help
~~~

`<reviewed-version>` 應替換成團隊已確認的實際版本；升級版本前請重新審查套件來源與變更內容。

setup 會替支援的 agent 建立 MCP 設定。完成後重新啟動 agent CLI；若使用自訂 MCP 設定，確認每個 agent 都包含 tmux-bridge server：

~~~json
{
  "mcpServers": {
    "tmux-bridge": {
      "command": "npx",
      "args": ["-y", "tmux-bridge-mcp@<reviewed-version>"]
    }
  }
}
~~~

Agent Bridge 不會在啟動失敗時偷偷下載或安裝 MCP server。可用 agent-bridge doctor 檢查 node、npx 與 tmux；MCP 設定仍需由使用者確認。

### 初始化目標專案（每個專案一次）

~~~bash
cd /path/to/your-project
agent-bridge setup
agent-bridge validate
~~~

setup 會建立 .ai-bridge.yaml、runtime 目錄與必要的 .gitignore 區塊。插件已安裝不代表專案已初始化；validate 是啟動前的必要檢查。跨 pane 溝通另外需要先完成 tmux-bridge-mcp 設定。

新專案的 session 會依目錄名稱自動命名，例如 Lucky50 會使用 Lucky50-ai，避免不同專案共用 agent-bridge-dev 而互相干擾。若設定檔已存在，setup 不會覆蓋其中的 session name。

### 啟動

可以使用 preset 快速選擇常見協作配置；未指定 preset 時，既有預設與設定檔行為不變：

~~~bash
agent-bridge up --preset standard
agent-bridge up --preset review
~~~

`standard` 使用 Codex + OpenCode + OpenCode；`review` 使用 Codex + OpenCode + Claude。若需要更細的控制，仍可直接使用各 runtime 參數。

~~~bash
agent-bridge up
~~~

啟動前會檢查專案、設定、tmux、python3 與設定中使用的 runtime。檢查失敗會停止，不會偷偷改用手動 tmux。

在一般互動式終端執行時，up 會啟動 workflow 並直接進入三個可見的 pane，使用者可以立即工作。這不是背景溝通，也不需要再執行 switch 或 tmux attach。

如果 workflow 已經存在，up 也會直接進入既有 session，不會要求使用者再手動執行 tmux attach。

只要前面的 tmux-bridge-mcp 設定已完成，三個 agent 就能透過 MCP 工具讀取其他 pane、傳送訊息並互相協作。Agent Bridge 負責「建立並顯示 pane」；tmux-bridge-mcp 負責「讓 agent 溝通」。

在 IDE、API 或其他 non-TTY 環境，up 才會在背景建立 session，並清楚印出 session 名稱與 attach 指令：

~~~text
READY session=... panes=3 ...
Attach with: tmux attach -t <session>
~~~

若之後離開 tmux，需要重新進入：

~~~bash
agent-bridge switch <session-name>
~~~

因此一般使用者的完整流程是：

~~~bash
# 每個專案第一次做一次
agent-bridge setup
npx -y tmux-bridge-mcp setup

# 之後每次開始工作
agent-bridge up
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

完整設定可以明確列出 orchestrator，並要求交接內容：

~~~yaml
agents:
  - id: codex
    runtime: codex
    pane: 0
    role: orchestrator
  - id: implementer
    runtime: opencode
    pane: 1
    role: implementation
  - id: reviewer
    runtime: opencode
    pane: 2
    role: review

workflow:
  notification: mailbox
  require_local_verification: true
  handoff_format:
    implementation_summary: required
    changed_files: required
    verification_result: required
    reviewer_status: required
~~~

orchestrator pane 必須是唯一且小於 pane_count；啟動器會在建立 tmux session 前檢查 pane 配置。

~~~text
.ai-bridge.yaml       # 共用設定，可提交
.ai-bridge/            # mailbox、PID、log、事件；不提交
.ai-bridge.local.yaml  # 個人覆寫，優先於共用設定
~~~

完成通知會在 mailbox 產生原有的 Markdown handoff，並另外產生同名 `.json` metadata。JSON 使用 `schema_version: 1`，只包含 agent、status、timestamp 與 Markdown 檔案路徑，不包含 pane 原文或敏感認證資訊。

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

`uninstall --force` 會不可逆地刪除該專案的 `.ai-bridge/` runtime 資料，包含 mailbox、PID 與 log；執行前請確認 `--project` 指向正確專案，必要時先備份需要保留的資料。

## 安全與信任模型

所有 pane 都不得把 API token、密碼、私鑰、環境變數內容或其他敏感認證資訊寫入 mailbox、log 或 handoff 訊息。Agent runtime 可能讀寫專案並執行命令，請只在可信任的專案與設定下使用。

設定檔、環境變數、parser、runtime 與啟動參數屬於使用者可自訂內容。若自行修改腳本、parser、設定格式或 runtime 行為，相關安全風險由修改者自行負責；`.gitignore` 也不是 secrets 保護機制。

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
