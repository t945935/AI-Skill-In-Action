# AI Skill 實戰

本專案用於撰寫《AI Skill 實戰：先找、再組、後自建》，教讀者從既有技能盤點開始，逐步完成 Skill 的選型、組合、自建、驗證與發布。

## 專案狀態

目前為新專案啟動工作區；作者與正式出版日期尚待確認。出版用狀態不放入讀者書稿，而記錄於專案文件。

## 讀者參考 GitHub repository

- 新書範例 repository：<https://github.com/t945935/AI-Skill-In-Action>
- 前作 OpenCode repository（僅作背景參考）：<https://github.com/t945935/opencode-deep-dive>
- 讀者操作方式與版本策略：[`docs/reader-github-guide.md`](docs/reader-github-guide.md)

## 目錄

- [`GETTING_STARTED.md`](GETTING_STARTED.md)：從 GitHub clone、安裝與第一個成功結果
- [`PROJECT_BRIEF.md`](PROJECT_BRIEF.md)：定位、讀者與交付目標
- [`BOOK_PLAN.md`](BOOK_PLAN.md)：重整後目錄與寫作順序
- [`STYLE_GUIDE.md`](STYLE_GUIDE.md)：書稿格式與用語規範
- [`GLOSSARY.md`](GLOSSARY.md)：術語基線
- [`FACTS.md`](FACTS.md)：需查證的版本與平台事實
- [`docs/store-listing.md`](docs/store-listing.md)：Google Play Books／Kobo 共用上架資料草稿
- [`docs/release-gates.md`](docs/release-gates.md)：出版前閘門與未決事項
- [`manuscript/chapters/`](manuscript/chapters/)：一個副章一個 Markdown 檔
- [`manuscript/appendices/`](manuscript/appendices/)：選型、測試、安全與發布範本
- [`examples/`](examples/)：讀者可下載與執行的範例
- [`assets/cover/cover.jpg`](assets/cover/cover.jpg)：已選定的 1600×2400 JPG 封面
- [`assets/cover/cover.svg`](assets/cover/cover.svg)：向量原始封面素材
- [`assets/cover/options/`](assets/cover/options/)：三款封面候選與風格說明

## 建議作業順序

1. 先完成 `PROJECT_BRIEF.md` 的作者、GitHub repository 與目標平台欄位。
2. 依 `BOOK_PLAN.md` 撰寫導讀與第一章。
3. 每完成一個副章，同步建立範例、測試與讀者操作說明。
4. 內容凍結後再建立 EPUB、執行 EPUBCheck 與裝置試讀。

## 建置合併稿

在 PowerShell 執行：

```powershell
.\tools\build-manuscript.ps1
```

合併稿會寫入 `output/manuscript.md`。目前作者、授權與 GitHub 遠端尚未確認，因此尚未標示正式出版版本。
