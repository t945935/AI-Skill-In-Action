# Skill 發行包範例

本範例示範一個可交付 Skill 應包含哪些檔案，以及發布前要留下哪些證據。這裡只建立本機候選結構，不推送 GitHub 或發布到外部平台。

## 建立候選包

在 repository 根目錄執行：

```powershell
.\tools\package-skill.ps1 -Version 0.1.0
```

腳本會拒絕覆寫既有版本，並在 `dist/book-chapter-review-v0.1.0/manifest.txt` 寫入檔案大小與 SHA-256。正式發布前仍需補入經確認的授權檔案與來源 commit。

## 建議結構

```text
book-chapter-review-v1.0.0/
├── SKILL.md
├── references/
├── templates/
├── tests/
├── README.md
├── CHANGELOG.md
├── LICENSE
└── manifest.txt
```

## 發行檢查

- [ ] 已固定版本與來源 commit
- [ ] 正向、負向、安全與回歸案例通過
- [ ] README 說明安裝、使用、限制與驗證
- [ ] CHANGELOG 說明輸入輸出與權限變更
- [ ] 已附授權與第三方依賴資訊
- [ ] `manifest.txt` 列出檔案、大小與 SHA-256
- [ ] 乾淨目錄安裝測試通過
- [ ] 外部推送或發布已由人工確認
