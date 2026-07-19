# Session 管理

Session 名稱是 tmux 的全域識別；同一部機器上，即使專案不同，也不可重複使用同一名稱。每個專案建議在設定檔使用唯一名稱。

## 不同 pane 配置

Agent Bridge 固定支援三種拓撲：

| pane_count | 0 | 1 | 2 | 3 |
| --- | --- | --- | --- | --- |
| 2 | orchestrator | implementer-a | - | - |
| 3 | orchestrator | implementer-a | reviewer | - |
| 4 | orchestrator | implementer-a | implementer-b | reviewer |

啟動範例：

~~~bash
agent-bridge up --config .ai-bridge.yaml
agent-bridge up --config .ai-bridge.dual.yaml
agent-bridge up --config .ai-bridge.quad.yaml
~~~

同一專案若要切換不同 workflow，必須使用不同 session 名稱，或先停止舊 session。up 會重用已存在的 session，不會自動重建不同 pane 拓撲。

~~~bash
agent-bridge down --session project-ai
agent-bridge up --config .ai-bridge.dual.yaml
~~~

每個專案應使用獨立名稱，例如 `my-project-ai`、`another-project-ai`。

## 查看所有 session

```bash
agent-bridge sessions
```

當前所在的 tmux session 會標記 `*`。

## 快速切換

```bash
agent-bridge switch my-project-ai
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
