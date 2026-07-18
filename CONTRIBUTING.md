# Contributing

## 開發檢查

提交前請執行：

```bash
./tests/smoke.sh
bash -n install.sh scripts/*.sh scripts/agent-bridge tests/*.sh
git diff --check
```

若修改 workflow、runtime 或 tmux lifecycle，必須補充對應測試。不要把 token、密碼、私鑰或完整環境資訊寫入測試輸出、mailbox、log 或 handoff。

## 相容性

既有命令與預設行為應保持相容。新功能應採 opt-in，設定變更需說明 migration 方式。依賴升級必須更新 `package-lock.json`，並使用 `--ignore-scripts` 進行 lockfile 驗證。

## 提交與發布

完成一個完整 phase 後再建立 commit；commit 前完成測試、資安掃描與工作區檢查。發布前確認 CI 在 Ubuntu 與 macOS 均通過。
