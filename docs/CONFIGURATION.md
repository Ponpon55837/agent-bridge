# 設定規範

專案設定檔為 `.ai-bridge.yaml`，個人覆寫檔為 `.ai-bridge.local.yaml`。runtime 目錄 `.ai-bridge/` 不應提交到 Git。

```yaml
project:
  name: my-project
  root: .

session:
  name: my-project-ai
  pane_count: 3

agents:
  - id: implementer
    runtime: opencode
    pane: 1
  - id: reviewer
    runtime: claude
    pane: 2

workflow:
  notification: mailbox
```

目前 launcher 會讀取 session 名稱、pane 數量，以及 implementer/reviewer runtime。CLI 明確傳入的參數優先於設定檔。

可用 runtime：`codex`、`opencode`、`claude`、`shell`。
