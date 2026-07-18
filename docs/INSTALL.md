# 導入與移除

## 導入

先在 Agent Bridge 專案內執行一次：

```bash
./install.sh
```

安裝完成後，進入目標專案執行：

```bash
agent-bridge setup
```

這會建立 `.ai-bridge/`、加入 Git ignore，並可選擇建立 `.ai-bridge.yaml`。不會把 Agent Bridge 腳本複製進目標專案。

## 啟動

```bash
agent-bridge up
```

需要客製 runtime 或 pane 時：

```bash
agent-bridge up --implementer-runtime opencode --reviewer-runtime claude --panes 4
```

## 移除

先預覽：

```bash
agent-bridge uninstall --project /你的專案
```

確認後：

```bash
agent-bridge uninstall --project /你的專案 --force
```

移除只會處理 Agent Bridge 建立的 runtime、session 與 Git ignore 區塊。

## 不同終端環境

安裝器會自動處理 zsh、Bash、Bash login shell 及一般 POSIX shell。若在 VSCode、tmux 或 IDE 內開的舊終端機找不到指令，先重開該終端機，或執行安裝器顯示的 `source` 指令。也可以使用完整路徑 `~/.local/bin/agent-bridge doctor` 進行診斷。
