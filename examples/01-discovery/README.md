# Skill inventory 實作

本範例示範如何在自行實作前盤點現成 Skill。請先把候選項目填入表格，再決定採用、組合、微調或自建。

## 盤點指令

PowerShell：

```powershell
$skillRoot = Join-Path $env:USERPROFILE '.codex\skills'
Get-ChildItem -LiteralPath $skillRoot -Directory |
  Sort-Object Name |
  Select-Object -ExpandProperty Name
```

Bash：

```bash
skill_root="$HOME/.codex/skills"
find "$skill_root" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
```

## 評估表

| 候選方案 | 來源 | 可處理的工作 | 輸入 | 輸出 | 權限／風險 | 決策與理由 |
|---|---|---|---|---|---|---|
|  |  |  |  |  |  |  |
|  |  |  |  |  |  |  |
|  |  |  |  |  |  |  |

## 驗收

- 至少列出三個候選方案，或記錄「查無合適方案」的搜尋範圍。
- 每個候選方案都讀過完整說明與限制。
- 每個決策都有一句可供日後重查的理由。
- 若決定自建，至少先寫出兩個正向案例與一個失敗案例。
