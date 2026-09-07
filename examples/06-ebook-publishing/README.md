# 電子書出版 Skill 整合案例

本範例把前幾章的能力串成出版工作流。它是設計與驗收範本，不會自動修改書稿、推送 GitHub 或上傳商店。

## 執行整合案例

在 repository 根目錄執行：

```powershell
.\examples\06-ebook-publishing\run-case.ps1
```

預期會重建合併稿與 EPUB，執行工作流／安全驗證，並建立 `dist/v0.1.5/` 候選發行包。若版本目錄已存在，請改用其他新版本；EPUBCheck、裝置試讀與商店提交仍是後續人工關卡。

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
