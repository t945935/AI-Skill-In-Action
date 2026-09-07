# Skill 工作流交接範例

本範例示範如何將書稿檢查、內容連貫檢查與 EPUB 驗證接成一條工作流。這裡不實作新的 Skill，而是先建立節點與交接契約。

## 執行

在 repository 根目錄執行：

```powershell
.\tools\run-workflow.ps1
```

預期會在 `reports/` 產生三份 `pass` 交接報告。若只想從某個節點重跑：

```powershell
.\tools\run-workflow.ps1 -FromStage epub-validation
```

這個 runner 只驗證輸入檔案與交接狀態，不假裝取代各宿主的 AI Skill；每個節點仍應依自己的契約重新檢查輸出。

## 節點表

| 節點 | 輸入 | 輸出 | 通過條件 | 失敗反應 |
|---|---|---|---|---|
| manuscript-check | Markdown、規範 | 檢查報告 | 無阻塞錯誤 | 停止修稿 |
| continuity-review | 書稿、章節計畫 | 問題清單 | 作者確認處理方式 | 暫停修改 |
| epub-validation | EPUB、封面 | 驗證結果 | 封裝與資源通過 | 不建立發行包 |

## 交接紀錄範本

```json
{
  "workflow": "ebook-release",
  "stage": "replace-with-stage-name",
  "input": [],
  "output": "replace-with-output-path",
  "status": "pass",
  "blocking_issues": [],
  "verified_at": "YYYY-MM-DD"
}
```

可接受的 `status`：

- `pass`：可交給下一節點。
- `pass_with_notes`：可暫存，但出版前要人工確認。
- `blocked`：不可進入下一節點。

## 驗收

- 至少完成三個節點的輸入輸出紀錄。
- 每個節點都能指出實際產物路徑。
- 至少模擬一次阻塞情況，確認流程不會跳過錯誤。
- 將發布或大量覆寫設定為人工確認，而非自動執行。
