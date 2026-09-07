# 開始使用

本指南以 Codex 的本機 Skill 目錄作為教學基線。其他宿主可能使用不同的安裝路徑或觸發方式，請先對照其官方文件。

## 取得讀者 repository

```bash
git clone https://github.com/t945935/AI-Skill-In-Action.git
cd AI-Skill-In-Action
```

書中範例以固定 tag 或 commit 為準；正式 tag 尚待發布前建立。不要直接依賴未驗證的最新分支。

## 必要條件

- Git
- PowerShell 7 或 Bash
- 可讀取 Skill 的 Codex／相容宿主
- 若要建置 EPUB 或第七章網頁教材：Pandoc

先確認專案檔案與範例目錄存在：

```powershell
Get-ChildItem manuscript, examples
```

## 安裝教學用 Skill（Codex 基線）

PowerShell：

```powershell
$skillRoot = Join-Path $env:USERPROFILE '.codex\skills\book-chapter-review'
New-Item -ItemType Directory -Force $skillRoot | Out-Null
Copy-Item -Recurse -Force examples\03-build-skill\* $skillRoot
```

Bash：

```bash
skill_root="$HOME/.codex/skills/book-chapter-review"
mkdir -p "$skill_root"
cp -R examples/03-build-skill/. "$skill_root/"
```

安裝後，要求宿主檢查一個指定副章，並確認它只產生報告、不覆寫原稿。若宿主沒有 `.codex/skills` 目錄，請改用該宿主的官方 Skill 安裝方式，不要猜測路徑。

## 先跑不需 AI 帳號的範例

先閱讀 [`examples/skills/skill-catalog.md`](examples/skills/skill-catalog.md)，確認每個候選 Skill 的來源、限制與驗收證據；不要因名稱相似就直接安裝。

```powershell
.\tools\list-skills.ps1
.\tools\run-security-fixtures.ps1
.\tools\run-workflow.ps1
```

第七章的靜態網頁教材案例使用同一套 Pandoc，不需要 Node.js、後端或外部 JavaScript 套件：

```powershell
.\examples\07-web-learning-material\run-case.ps1
```

成功時會建立 `examples/07-web-learning-material/site/`，並輸出內容契約、導覽、無障礙基線與安全 fixture 的檢查結果；正式部署仍停在人工確認點。

最後一個命令會在未提交的 `reports/` 產生交接報告。若要建置本書草稿：

```powershell
.\tools\build-manuscript.ps1
```

## 遇到問題時

請回報作業系統、PowerShell／Bash 版本、執行的固定 commit、完整錯誤訊息與受影響的範例目錄。不要貼出 API Key、Token 或私人檔案內容。
