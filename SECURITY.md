# Security Policy

## Trust model

Agent runtime 可能讀寫專案並執行命令。請只在可信任的專案、設定與 runtime 下使用；設定檔與環境變數不應含 secrets。

所有 pane 都不得將 API token、密碼、私鑰、完整環境變數或其他認證資訊寫入 mailbox、log、handoff 或訊息。

## Reporting

請不要在公開 issue 貼出 token、私鑰、完整 log 或未修補的可利用細節。請透過 repository owner 指定的私下管道回報，並提供重現步驟、受影響版本與最小必要證據。

## Release checks

- Shell/Python 語法檢查
- smoke 與 tmux lifecycle 測試
- shellcheck CI
- secrets pattern scan
- npm lockfile integrity 驗證
- Ubuntu 與 macOS CI
