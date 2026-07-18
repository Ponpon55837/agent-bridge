# Agent Bridge

Agent Bridge 是一套可導入不同專案的多代理協作工具。它使用 tmux 建立多個工作區，讓總控、實作者與審查者可以在同一個 workflow 中協作，並透過 mailbox 事件檔傳遞完成通知。

目前支援的 runtime：

- Codex
- OpenCode
- Claude
- 其他可由 shell 啟動的 CLI 工具

## 第一次安裝

先確認環境：

```bash
tmux -V
python3 --version
```

先取得 Agent Bridge 並進入它的目錄。這個步驟只需要做一次：

```bash
git clone <agent-bridge-repository>
cd agent-bridge
./install.sh
```

安裝程式會把 `agent-bridge` 放到 `~/.local/bin`，並自動設定 zsh、bash 或一般 shell 的啟動設定。安裝完成後請關閉目前終端機，再開一個新的終端機。

確認安裝：

```bash
agent-bridge doctor
```

如果目前終端機還找不到指令，這通常只是舊終端機尚未載入新設定。請重開終端機；不想重開時，可執行安裝器提示的 `source` 指令。

## 導入專案

之後不需要再輸入 Agent Bridge 的完整路徑。進入要導入的專案目錄：

```bash
cd /你的專案路徑
```

第一次導入專案：

```bash
agent-bridge setup
```

啟動 workflow：

```bash
agent-bridge up
```

`up` 會依專案資料夾名稱自動建立 session，例如專案叫 `Lucky50`，session 預設會叫 `Lucky50-ai`。
如果 session 已經存在，`up` 會直接進入既有 session，不會重複建立 pane。

## 啟動後怎麼使用

查看所有 session：

```bash
agent-bridge sessions
```

進入目前專案的 session：

```bash
agent-bridge switch Lucky50-ai
```

或直接使用 tmux：

```bash
tmux attach -t Lucky50-ai
```

預設 pane 分工：

| Pane | 角色 | 說明 |
|---|---|---|
| 0 | 總控 | 預設自動啟動 Codex |
| 1 | 實作者 | 執行總控派發的程式修改 |
| 2 | 審查者 | 檢查修改、測試與回歸風險 |
| 3 以上 | 預留 | 給額外 agent 或專案角色使用 |

啟動器只會在 pane 0 啟動 Codex CLI，不會注入工作提示或訊息，因此不會干擾總控輸入框。若想手動啟動總控，可設定 `orchestrator_runtime: none`。

## 日常指令

```bash
# 查看目前專案與 session 狀態
agent-bridge status

# 列出所有 session，當前 tmux session 會標記 *
agent-bridge sessions

# 停止目前專案的預設 session
agent-bridge down

# 重新啟動
agent-bridge up

# 檢查本機工具是否安裝
agent-bridge doctor
```

## 多專案與 session 管理

不同專案請使用不同 session 名稱：

```bash
agent-bridge up --project /projects/lucky50 --session lucky50-ai
agent-bridge up --project /projects/shop --session shop-ai
```

列出並確認目前所在位置：

```bash
agent-bridge sessions
```

快速切換：

```bash
agent-bridge switch shop-ai
```

更名 session：

```bash
agent-bridge rename old-name new-name
```

刪除不再使用的 session：

```bash
agent-bridge kill --session old-name
```

指令預設會要求確認。確定名稱無誤時，才使用：

```bash
agent-bridge kill --session old-name --force
```

## 指定不同 runtime 或更多 pane

一般使用不需要指定；需要客製時可以這樣啟動：

```bash
agent-bridge up \
  --implementer-runtime opencode \
  --reviewer-runtime claude \
  --panes 4
```

可用 runtime：`codex`、`opencode`、`claude`、`shell`。

## 專案設定

`setup` 會在目標專案建立：

```text
.ai-bridge.yaml       # 專案共用設定，可提交
.ai-bridge/           # runtime 狀態，不提交
.ai-bridge.local.yaml # 個人覆寫，不提交
```

runtime 目錄包含：

- mailbox 事件檔
- supervisor PID
- supervisor log
- session lifecycle events

這些檔案已加入 `.gitignore`，不會污染專案 Git。

要增加或減少 pane，直接修改 `.ai-bridge.yaml` 的 `session.pane_count`。修改後先執行 `agent-bridge down`，再執行 `agent-bridge up`；既有 tmux session 不會自動重建。

## 移除導入

先預覽：

```bash
agent-bridge uninstall --project /你的專案路徑
```

確認後執行：

```bash
agent-bridge uninstall --project /你的專案路徑 --force
```

移除會：

- 停止指定 supervisor
- 關閉指定 session
- 刪除 `.ai-bridge/`
- 移除 Agent Bridge 自己加入的 `.gitignore` 區塊

移除不會刪除：

- 專案原始碼
- Git commit 或 branch
- 其他 tmux session
- 使用者自行建立的設定內容

## 常見問題

### 找不到 `agent-bridge`

先在 Agent Bridge 專案目錄重新執行：

```bash
./install.sh
```

如果仍找不到，確認：

```bash
echo "$PATH"
ls -l "$HOME/.local/bin/agent-bridge"
```

### session 已存在

這是安全行為，啟動器不會重複建立 pane。直接切換進既有 session：

```bash
agent-bridge switch <session-name>
```

### runtime 沒有安裝

執行：

```bash
agent-bridge doctor
```

缺少的 runtime 只會在你把它指定為 implementer 或 reviewer 時造成啟動失敗。

### 想確認所有檔案是否正確

在 Agent Bridge 專案內執行：

```bash
./scripts/agent-bridge validate
./tests/smoke.sh
```

## 開發文件

- [快速開始](docs/QUICKSTART.md)
- [導入與移除](docs/INSTALL.md)
- [設定規範](docs/CONFIGURATION.md)
- [Session 管理](docs/SESSIONS.md)
- [開發規範](docs/DEVELOPMENT.md)
- [產品 Roadmap](ROADMAP.md)

## 更新設定範例

Agent Bridge 更新後若需要新版設定欄位：

```bash
agent-bridge setup --refresh-config
```

這會先備份目前設定為 `.ai-bridge.yaml.bak`，再建立新版範例。一般 `agent-bridge setup` 不會覆蓋既有設定。
