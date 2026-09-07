# 學習者走讀報告

走讀角度：第一次接觸 Skill、只依書稿與讀者 repository 操作的人。  
走讀範圍：導讀、六個正文單元、六份附錄與六組範例。

## 總結

以下總結描述修正前基線；概念學習路線是連貫的：先盤點，再組合，接著自建、驗證，最後治理與整合案例。當時真正的卡關不在觀念，而在「範例尚未形成可從乾淨目錄重跑的最小專案」。

## 走讀結果（修正前基線）

以下表格保留初次走讀時的阻塞紀錄，供回顧使用；修正後的現況見「修正後驗收」。

| 位置 | 學習者動作 | 結果 | 嚴重度 |
|---|---|---|---|
| 導讀 | 了解學習路線 | 可順利進入第一章 | 低 |
| 第一章 | 列出本機 Skill、填寫 inventory | 在已有 `.codex/skills` 的環境可執行；沒有目錄時會直接報錯，且沒有示範填好的結果 | 中 |
| 第二章 | 建立工作流交接資料 | 可產生 `workflow.json`，但只停在 `planned`；沒有任何指令真正執行三個節點，也沒有 `reports/` 或實際交接檔 | 高 |
| 第三章 | 建立並安裝 `SKILL.md` | 能讀懂檔案，但「目標工具支援的目錄」未指定，沒有安裝、觸發與預期輸出步驟 | 高 |
| 第四章 | 執行正向、負向與安全測試 | 三個 fixture 只有 README，缺少實際章節、術語表、規範與測試執行器，無法重現矩陣 | 高 |
| 第五章 | 建立版本化發行包 | 只有目錄樹與檢查表，沒有產生 `manifest.txt`、SHA-256、LICENSE 的命令或腳本 | 高 |
| 第六章 | 依案例完成 EPUB 出版流程 | 有狀態圖與清單，但沒有可執行的端到端範例專案、平台設定或實際輸出 | 高 |
| 附錄 | 查找範本與清單 | 參考價值高，但不能補足前述執行斷點 | 低 |

## 會真正卡住的地方

### 開始前沒有可用的 GitHub 入口

`README.md`、`PROJECT_BRIEF.md` 與 `docs/reader-github-guide.md` 都把 repository URL、分支、tag 與授權列為待指定。讀者無法知道要 clone 哪個位置，也無法取得書中所說的固定版本。這是全書第一個阻塞點。

**修正建議**

- 建立一個公開或可讀取的 repository，先發布 `v0.1.0` 或固定 commit。
- 新增 `GETTING_STARTED.md`，放入 clone 指令、支援的宿主、必要版本與第一個成功結果。
- 將同一組 URL、tag 與授權同步到 `PROJECT_BRIEF.md`、`FACTS.md`、README 與每個範例。

### 第一章的盤點指令沒有「查無目錄」分支

PowerShell 與 Bash 指令直接讀取 `.codex/skills`。第一次使用或使用不同宿主時，讀者會得到路徑不存在錯誤，卻不知道這代表「尚未安裝」還是「路徑不同」。此外，inventory 表格是空白的，沒有一份完整示例可對照。

**修正建議**

- 提供跨平台的 `tools/list-skills.ps1` 與 `tools/list-skills.sh`；目錄不存在時輸出清楚訊息與下一步。
- 增加 `inventory.sample.md`，示範三個候選方案、來源、限制與決策理由。
- 將「本機 Skill」「專案 Skill」「公開 repository／插件」分成三個可勾選來源。

### 第二章只建立狀態檔，沒有真正跑工作流

書中指令會產生 `.skill-run/workflow.json`，但狀態仍是 `planned`。讀者不知道如何呼叫每個節點、如何產生報告、如何把 `pass` 傳給下一步，也沒有中斷後重跑的命令。`.skill-run` 也沒有忽略規則，容易被誤提交。

**修正建議**

- 提供一個最小 `workflow.json` 範例與三個假的但可驗證的 stage runner。
- 建立 `reports/` 與 `runs/` 的約定，列出每個產物的確切檔名。
- 增加 `tools/run-workflow.ps1` 或等效腳本，支援 `--from`／`-FromStage` 重新開始。
- 將 `.skill-run/` 加入 `.gitignore`，並在書中說明哪些報告應提交。

### 第三章沒有指定 Skill 的安裝與觸發方式

`SKILL.md` 範例本身界線清楚，但「複製到目標工具支援的 Skill 目錄」對學習者而言不可操作。不同宿主可能有不同的目錄、觸發語法與 front matter 欄位；本章只提醒讀者查官方文件，沒有提供至少一個確定宿主的完整路徑。

**修正建議**

- 選定一個教學基線（例如本書讀者 repository 支援的宿主），提供安裝路徑與觸發提示的完整步驟。
- 另加「其他宿主的差異」小節，將可變部分集中到表格。
- 附上一次成功執行的輸入、輸出報告與未修改檔案的差異證據。

### 第四章的 fixture 不能執行

`fixtures/complete/`、`missing-glossary/` 與 `untrusted-instructions/` 目前各只有 README。讀者被要求「先執行」案例，卻沒有可供 Skill 讀取的 Markdown、GLOSSARY 或規範檔，也沒有測試器比較實際與預期結果。

**修正建議**

- 在每個 fixture 放入最小必要檔案，例如 `chapter.md`、`GLOSSARY.md`、`STYLE_GUIDE.md`。
- 在不可信內容 fixture 放入固定的提示注入文字，並明確標示它是資料。
- 新增 `tools/run-security-fixtures.ps1` 或 Python runner，輸出 `pass`／`blocked`／`fail`。
- 保留一份預期報告，讓讀者能做差異比對。

### 第五章的發行流程停在概念層

讀者看得到 `manifest.txt`、SHA-256 與 LICENSE 應該存在，卻沒有命令可以產生它們，也沒有一個實際的候選發行包。這會讓「可追溯性」最需要實作的章節變成閱讀題。

**修正建議**

- 提供 `tools/package-skill.ps1` 或跨平台 Python 腳本。
- 腳本接受版本與輸出目錄，拒絕覆寫既有版本，並產生 manifest、雜湊與測試摘要。
- 在範例中附最小 `LICENSE` 與依賴清單，說明哪些欄位仍需出版者確認。
- 加一個乾淨目錄安裝測試，確定發行包不是只在作者電腦可用。

### 第六章沒有可完成的端到端成果

整合案例的狀態圖與檢查表設計正確，但缺少一個讀者可以 clone、執行、看到 EPUB 與報告的最小專案。讀者因此無法驗證「前五章真的接起來了」。

**修正建議**

- 在讀者 repository 放一個小型示例書（兩個副章即可），避免先要求讀者準備整本書。
- 提供從 `draft` 到 `release-candidate` 的單一命令與每階段預期產物。
- 將 EPUB 建置、封面、驗證與發行包命令集中在 `GETTING_STARTED.md`，正文只解釋取捨。
- 加入一次故意失敗的案例，展示如何回到前一狀態並重跑。

## 已經做得好的地方

- 章節順序符合學習曲線，沒有先教自建再談選型的倒置問題。
- 每章都有目標、核心概念、實作、常見錯誤與小結。
- 「不可處理的工作」、人工閘門與提示注入防護寫得清楚。
- 電子書出版案例能把 Skill 的輸入輸出、狀態與責任串起來。
- 附錄適合當作日後工作卡與審查清單。

## 修正優先順序

1. **先補入口**：確定 GitHub URL、固定 tag、支援宿主與安裝方式。
2. **再補可跑範例**：完成第四章 fixture 與測試器，因為它是後續章節的驗證基礎。
3. **補工作流 runner**：讓第二章與第六章能真的產生交接產物。
4. **補發行腳本**：產生 manifest、SHA-256、LICENSE 與乾淨安裝測試。
5. **最後做學習者回歸走讀**：在乾淨目錄從 README 開始，不使用作者本機已存在的 Skill 或檔案。

## 結論

走讀初版是「概念與設計完成、實作教材尚未封口」的版本。本輪已依卡關清單補上可下載、可執行、可看到預期結果的最小案例；仍需在 GitHub 乾淨 clone 上做一次獨立回歸走讀。

## 修正後驗收

以目前候選版本執行：

- `tools/run-workflow.ps1`：三個節點均為 `pass`，並檢查章節／附錄數量、內部連結、章節必要欄位與 EPUB 資源。
- `tools/run-security-fixtures.ps1`：完整案例 `pass`、缺少術語表 `blocked`、不可信內容 `flagged`，且 fixture 完整性通過。
- `tools/package-release.ps1 -Version 0.1.5`：產生含 EPUB、封面、metadata、manifest、SHA-256 與狀態檔的候選包。

## 本輪已處理

- 已固定讀者 repository：`https://github.com/t945935/AI-Skill-In-Action`。
- 已新增 `GETTING_STARTED.md`、跨平台 Skill 盤點腳本與宿主安裝說明。
- 已新增工作流 `workflow.json`、`run-workflow.ps1` 與可重跑的交接報告。
- 已補齊安全 fixture 與 `run-security-fixtures.ps1`，可輸出預期狀態。
- 已新增 `package-skill.ps1`，可建立版本目錄與 manifest／SHA-256。
- 已新增電子書出版 `run-case.ps1`，並在各範例 README 補上實際命令。

仍待人工完成：正式 repository tag、授權條款、作者／出版資料、最新 EPUBCheck、實機試讀與外部發布授權。
