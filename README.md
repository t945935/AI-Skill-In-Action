# AI Skill 實戰

本專案用於撰寫《AI Skill 實戰：先找、再組、後自建》，教讀者從既有技能盤點開始，逐步完成 Skill 的選型、組合、自建、驗證與發布。

## 專案狀態

目前為讀者可用的 `v0.1.1` 候選版。讀者可從 `main` 分支取得範例；正式 tag、授權與商店出版欄位仍在發布閘門中確認。詳細狀態見 [`PROJECT_STATUS.md`](PROJECT_STATUS.md)。

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
- [`docs/risk-register.md`](docs/risk-register.md)：風險、負責角色與應對策略
- [`docs/raci.md`](docs/raci.md)：專案角色與責任分工
- [`docs/compatibility-matrix.md`](docs/compatibility-matrix.md)：工具與宿主相容性基線
- [`manuscript/chapters/`](manuscript/chapters/)：一個副章一個 Markdown 檔
- [`manuscript/appendices/`](manuscript/appendices/)：選型、測試、安全與發布範本
- [`examples/`](examples/)：讀者可下載與執行的範例
- [`assets/cover/cover.jpg`](assets/cover/cover.jpg)：已選定的 1600×2400 JPG 封面
- [`assets/cover/cover.svg`](assets/cover/cover.svg)：向量原始封面素材
- [`assets/cover/options/`](assets/cover/options/)：三款封面候選與風格說明

## 建議作業順序

1. 先閱讀 [`GETTING_STARTED.md`](GETTING_STARTED.md)，固定 repository commit 與必要工具。
2. 依 `BOOK_PLAN.md` 撰寫導讀與第一章。
3. 每完成一個副章，同步建立範例、測試與讀者操作說明。
4. 內容凍結後再建立 EPUB、執行 EPUBCheck 與裝置試讀。

## 建置合併稿

在 PowerShell 執行：

```powershell
.\tools\build-manuscript.ps1
```

合併稿會寫入 `output/manuscript.md`。目前來源是 `manuscript/` 與 `styles/`；正式出版前仍須通過最新 EPUBCheck、實機試讀與身份／授權確認。
