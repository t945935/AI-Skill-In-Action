# 電子書出版 Skill 整合案例

本範例把前幾章的能力串成出版工作流。它是設計與驗收範本，不會自動修改書稿、推送 GitHub 或上傳商店。

## 案例輸入

執行前先確認下列來源存在；不要直接拿 `output/` 或 `dist/` 當成書稿來源。

| 輸入 | 路徑 | 用途 |
|---|---|---|
| 章節與附錄 | `manuscript/` | 合併稿來源 |
| 書籍資料 | `metadata/book.yaml` | EPUB metadata |
| 閱讀樣式 | `styles/book.css` | EPUB CSS |
| 正式封面 | `assets/cover/cover.jpg` | EPUB 與發行包封面 |
| 上架草稿 | `docs/store-listing.md` | 商店欄位交接 |
| 發布閘門 | `docs/release-gates.md` | 區分已驗證與待人工確認項目 |

開始前執行 `git status --short`，確認哪些修改屬於本次作業。版本名稱必須是尚未存在的新名稱；腳本會拒絕覆寫既有候選包。

## 執行整合案例

在 repository 根目錄執行：

```powershell
.\examples\06-ebook-publishing\run-case.ps1 -Version 0.2.1-local
```

預期會重建合併稿與 EPUB，執行工作流／安全驗證，建立 `dist/v0.2.1-local/` 練習用候選發行包，再驗證必要檔案、manifest 與 SHA-256。成功結尾如下：

```text
package-files: pass
checksum-verification: pass
manifest-traceability: pass
release-gate: awaiting-human-approval
case-complete: v0.2.1-local
```

若版本目錄已存在，改用另一個練習版本，不可刪除或覆寫原包。EPUBCheck、裝置試讀與商店提交仍是後續人工關卡。

若只需要重新驗收既有候選包，執行：

```powershell
.\examples\06-ebook-publishing\verify-package.ps1 -Version 0.2.1-local
```

測試或持續整合可用 `-OutputRoot` 指定隔離目錄，避免把暫存候選包混入正式 `dist/`。

```powershell
.\examples\06-ebook-publishing\run-case.ps1 `
  -Version 0.0.0-test `
  -OutputRoot C:\Temp\ai-skill-book-test
```

## 狀態流程

```text
draft → reviewed → buildable → validated → release-candidate → ready-to-submit
```

任何阻塞問題都必須停下來，不可跳過驗證直接進入下一狀態。

## 階段檢查表

- [ ] 已盤點現成書稿、連貫性、EPUB 與發行能力
- [ ] 已寫出輸入輸出契約與責任邊界
- [ ] 章節結構與範例檔案通過檢查
- [ ] 負向與安全案例通過
- [ ] EPUB 與封面完成獨立驗證
- [ ] 發行包包含 manifest、SHA-256 與 CHANGELOG
- [ ] 作者、授權、日期與平台資料由出版者確認
- [ ] 外部推送、上傳或發布已取得明確授權

## 產物交接

每個階段都應留下報告或檔案路徑，下一階段重新驗證必要輸入。不要只在聊天紀錄中寫「已完成」。

候選包至少應包含：

```text
dist/v<version>/
├── AI-Skill-In-Action.epub
├── cover.jpg
├── book.yaml
├── store-listing.md
├── release-gates.md
├── RELEASE_STATUS.md
├── manifest.txt
└── SHA256SUMS.txt
```

`verify-package.ps1` 通過只表示包內檔案齊全、雜湊一致且來源可追溯。看到 `release-gate: awaiting-human-approval` 是正確結果，不得把它改寫為發布成功。

## 失敗後怎麼處理

| 現象 | 原因 | 修正方式 |
|---|---|---|
| 找不到 Pandoc | 建置工具未安裝或不在 PATH | 安裝後開啟新的 PowerShell，再確認 `pandoc --version` |
| 缺少封面或書籍資料 | 必要輸入不完整 | 修正來源路徑，不要放空白替代檔 |
| 工作流顯示 `blocked` | 章節、連結或必要資源未通過 | 依 `reports/` 的阻塞訊息修正來源後重跑 |
| `SHA-256 不符` | 候選包建立後有檔案被改動 | 回到來源修正並建立新版本，不在舊包內直接修改 |
| 拒絕覆寫發行目錄 | 相同版本已存在 | 保留舊包，改用新的版本名稱 |
