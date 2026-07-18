# 快速開始

第一次使用先安裝一次：

```bash
cd agent-bridge
./install.sh
```

安裝完成後請關閉目前終端機，再開一個新的終端機；這樣系統才會找到 `agent-bridge` 指令。

之後進入任何要導入的專案，日常只需要四個指令：

```bash
cd /你的專案
agent-bridge setup
agent-bridge up
agent-bridge status
agent-bridge down
```

如果尚未加入 PATH，將 `agent-bridge` 換成完整路徑：

```bash
/path/to/agent-bridge/scripts/agent-bridge up
```

`setup` 負責導入專案，`up` 負責啟動 session，`status` 顯示狀態，`down` 停止 session。
