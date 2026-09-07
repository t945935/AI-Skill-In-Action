# 網頁版教材製作 Skill 整合案例

本範例示範如何把 Markdown 課程轉成可在瀏覽器閱讀的靜態網頁教材。它刻意維持小型、可理解的結構：一個首頁、兩課內容頁、共用版型、響應式導覽、學習完成狀態，以及可重複執行的驗證腳本。

建置只會讀取 `source/` 與 `templates/`，產物寫入 `site/`。範例不會上傳網站、修改來源教材，也不會載入遠端 JavaScript 或 CSS。

## 使用前準備

- Windows PowerShell 5.1 或 PowerShell 7。
- Pandoc；可在 PowerShell 執行 `pandoc --version` 確認。
- Python 只用於本機預覽，不是建置必要條件。

## 第一個成功結果

在 repository 根目錄執行：

```powershell
.\examples\07-web-learning-material\run-case.ps1
```

成功時只會顯示：

```text
content-contract: pass
site-build: pass
navigation-check: pass
accessibility-baseline: pass
security-fixtures: pass
deployment-gate: awaiting-human-approval
```

接著啟動本機伺服器：

```powershell
python -m http.server 8000 --directory .\examples\07-web-learning-material\site
```

用瀏覽器開啟 <http://localhost:8000/>。按 `Ctrl+C` 可停止伺服器。

## 分開執行建置與測試

只重建網站：

```powershell
.\examples\07-web-learning-material\scripts\build-course.ps1
```

只驗證已建好的網站與三組 fixture：

```powershell
.\examples\07-web-learning-material\scripts\test-course.ps1
```

完成人工走查後，可建立不覆寫既有版本的部署候選包：

```powershell
.\examples\07-web-learning-material\scripts\package-course.ps1 -Version 0.1.0
```

候選包位於 `examples/07-web-learning-material/dist/v0.1.0/`，包含網站、狀態、manifest 與 SHA-256；這個命令仍不會部署網站。

## 修改教材

1. 在 `source/course.json` 登記課程與課次資料。
2. 在 `source/lessons/` 編輯對應的 Markdown。
3. 再次執行 `run-case.ps1`。
4. 檢查 `site/`，並以鍵盤及窄螢幕實際走讀。

每課必須有不重複的 `id`、`title`、`file` 與 `objective`。若使用 Markdown 圖片，替代文字不可為空，且圖片必須放在 `source/media/`，並以 `media/檔名` 引用。

## 目錄

```text
07-web-learning-material/
├─ README.md
├─ SKILL.md
├─ browser-qa.md           # 三種視窗與互動的走查證據
├─ run-case.ps1
├─ source/                 # 唯讀教材來源
├─ templates/              # HTML、CSS、JavaScript 版型
├─ scripts/                # 建置與驗證腳本
├─ fixtures/               # 正向、缺漏與不安全案例
├─ site/                   # 執行建置後產生，不應手動編輯
└─ dist/                   # 人工走查後才建立的版本化候選包
```

## 安全與發布邊界

- Pandoc 以停用 raw HTML 的模式轉換 Markdown。
- `script`、`iframe`、事件處理屬性及 `javascript:` URL 會在建置前被攔截。
- 建置器先在暫存目錄完成新網站，再交換成 `site/`，不會把來源當成輸出目錄。
- `run-case.ps1` 最後停在 `awaiting-human-approval`。正式部署前仍須由人確認網址、素材授權、公開範圍、隱私設定及託管平台。
- 本次瀏覽器走查結果記錄在 `browser-qa.md`；修改內容或版型後必須重新走查，不可直接沿用舊結果。

## 常見問題

若看到「找不到 Pandoc」，請先安裝 Pandoc 並重新開啟 PowerShell。若看到 `[CONTRACT]`，先檢查 `course.json` 的必填欄位與檔案路徑；看到 `[SECURITY]` 時，不要略過檢查，應移除不安全內容或改用純 Markdown 表達。
