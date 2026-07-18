# Session 管理

每個專案應使用獨立名稱，例如 `lucky50-ai`、`shop-ai`。

## 查看所有 session

```bash
agent-bridge sessions
```

當前所在的 tmux session 會標記 `*`。

## 快速切換

```bash
agent-bridge switch lucky50-ai
```

在 tmux 內會切換目前 client；在 tmux 外會直接 attach。

## 更名

```bash
agent-bridge rename old-name new-name
```

名稱只能使用英文字母、數字、底線與連字號，且不會覆蓋既有 session。

## 刪除

```bash
agent-bridge kill --session old-name
```

預設會要求確認。確定後才使用 `--force`。刪除 session 不會自動刪除專案 runtime；兩者要分開操作。
