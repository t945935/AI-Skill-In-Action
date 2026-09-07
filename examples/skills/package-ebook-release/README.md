# package-ebook-release

- 類別：發行封裝
- 用途：建立不可覆寫、可追溯的版本化書籍發行目錄。
- 觸發：內容與技術驗證通過，準備建立候選或正式版本時。
- 輸入：合併稿、EPUB、封面、metadata、測試結果與版本號。
- 輸出：`dist/v<version>/`、manifest、SHA-256 與 release 狀態。
- 驗收：來源 commit、建置時間、檔案清單、雜湊與已知限制齊全。
- 限制：不覆寫既有版本；正式 tag 與外部發布仍需人工確認。
- 來源／版本／授權：依宿主提供的 `SKILL.md` 查證；本 repo 只提供導覽。
