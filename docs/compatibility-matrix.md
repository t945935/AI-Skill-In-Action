# 相容性矩陣

本表是讀者與維護者的基線；工具升版後需重跑工作流、安全 fixture 與 EPUB 建置。

| 元件 | 基線 | 驗證方式 | 狀態 |
|---|---|---|---|
| Git | 可執行 `clone`、`checkout` | `git --version` | 必要 |
| PowerShell | 7.x 建議；Windows PowerShell 5.1 可嘗試 | `pwsh --version`／`$PSVersionTable` | 需實機確認 |
| Bash | GNU Bash 4+ | `bash --version` | 需實機確認 |
| Pandoc | 具 EPUB 輸出與 YAML metadata 支援 | `pandoc --version` | 建置必要 |
| 現代瀏覽器 | 支援 HTML5、CSS Grid 與 `localStorage` | 桌面與手機尺寸人工走查 | 網頁教材必要 |
| Codex／相容宿主 | 支援 `SKILL.md` 與目標 front matter | 依宿主官方文件 | 待查證 |
| EPUBCheck | 最新穩定版 | 外部 EPUBCheck 執行結果 | 待人工確認 |

版本、作業系統與執行日期應寫入每次發布的 manifest；不要只記錄「可用」。網頁教材正式部署前，另須確認目標主機、公開 URL、素材授權與隱私設定。
