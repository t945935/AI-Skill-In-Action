# fix-google-books-warnings

- 類別：平台警告修正
- 用途：診斷 Google Play Books 對 EPUB CSS、metadata、封面或資源的處理警告。
- 觸發：平台回報具體 warning，且已有可重現的候選 EPUB 時。
- 輸入：警告原文、候選 EPUB、來源 CSS／metadata 與修正前後雜湊。
- 輸出：原因、最小修正、重建檔案與再次驗證結果。
- 驗收：每項警告可對應到來源或 EPUB 內部資源；不以猜測代替平台結果。
- 限制：只處理已提供的警告；不自動上傳或發布商店版本。
- 來源／版本／授權：依宿主提供的 `SKILL.md` 與平台文件查證；本 repo 只提供導覽。
