param(
  [string]$WorkflowPath = 'examples/02-composition/workflow.json',
  [string]$FromStage = ''
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Get-Location).Path
$workflow = Get-Content -LiteralPath (Join-Path $projectRoot $WorkflowPath) -Raw | ConvertFrom-Json
$reportRoot = Join-Path $projectRoot 'reports'
New-Item -ItemType Directory -Force $reportRoot | Out-Null

function Resolve-ProjectPath([string]$relativePath) {
  return Join-Path $projectRoot $relativePath
}

function Test-MarkdownLinks {
  $broken = @()
  foreach ($file in (Get-ChildItem -LiteralPath (Resolve-ProjectPath 'manuscript') -Recurse -Filter '*.md')) {
    $text = Get-Content -LiteralPath $file.FullName -Raw
    foreach ($match in [regex]::Matches($text, '\[[^\]]+\]\(([^)#]+)(?:#[^)]+)?\)')) {
      $target = $match.Groups[1].Value
      if ($target -match '^(https?|mailto):') { continue }
      $resolved = Join-Path $file.DirectoryName $target
      if (-not (Test-Path -LiteralPath $resolved)) { $broken += "$($file.FullName): $target" }
    }
  }
  return $broken
}

function Invoke-StageCheck([string]$name) {
  $details = @()
  switch ($name) {
    'manuscript-check' {
      $chapters = @(Get-ChildItem -LiteralPath (Resolve-ProjectPath 'manuscript/chapters') -Filter '*.md')
      $appendices = @(Get-ChildItem -LiteralPath (Resolve-ProjectPath 'manuscript/appendices') -Filter '*.md')
      $requiredChapters = @(
        '00-preface.md',
        '01-discover-before-build.md',
        '02-compose-workflow.md',
        '03-build-skill.md',
        '04-verify-secure.md',
        '05-release-governance.md',
        '06-ebook-publishing-case.md',
        '07-web-learning-material-case.md'
      )
      $chapterNames = @($chapters | ForEach-Object { $_.Name })
      foreach ($requiredChapter in $requiredChapters) {
        if ($chapterNames -notcontains $requiredChapter) { throw "缺少必要章節：$requiredChapter" }
      }
      if ($appendices.Count -lt 5) { throw "附錄數量不足：$($appendices.Count)" }
      foreach ($requiredWebCaseFile in @(
        'examples/07-web-learning-material/README.md',
        'examples/07-web-learning-material/SKILL.md',
        'examples/07-web-learning-material/browser-qa.md',
        'examples/07-web-learning-material/run-case.ps1',
        'examples/07-web-learning-material/source/course.json',
        'examples/07-web-learning-material/scripts/build-course.ps1',
        'examples/07-web-learning-material/scripts/test-course.ps1',
        'examples/07-web-learning-material/scripts/package-course.ps1'
      )) {
        if (-not (Test-Path -LiteralPath (Resolve-ProjectPath $requiredWebCaseFile))) { throw "缺少第七章範例：$requiredWebCaseFile" }
      }
      $broken = @(Test-MarkdownLinks)
      if ($broken.Count -gt 0) { throw "發現失效內部連結：$($broken -join '; ')" }
      $details += "導讀與第一至第七章、附錄 $($appendices.Count) 份、第七章範例及內部連結通過。"
    }
    'continuity-review' {
      foreach ($file in (Get-ChildItem -LiteralPath (Resolve-ProjectPath 'manuscript/chapters') -Filter '*.md')) {
        $text = Get-Content -LiteralPath $file.FullName -Raw
        foreach ($required in @('本章目標', '核心概念', '練習', '本章小結')) {
          if ($text -notmatch [regex]::Escape($required)) { throw "$($file.Name) 缺少：$required" }
        }
      }
      $details += '每個正文副章均包含目標、概念、練習與小結。'
    }
    'epub-validation' {
      $epubPath = Resolve-ProjectPath 'output/AI-Skill-In-Action.epub'
      if (-not (Test-Path -LiteralPath $epubPath)) { throw '找不到 output/AI-Skill-In-Action.epub' }
      Add-Type -AssemblyName System.IO.Compression.FileSystem
      $zip = [IO.Compression.ZipFile]::OpenRead($epubPath)
      try {
        $names = @($zip.Entries | ForEach-Object { $_.FullName })
        foreach ($required in @('mimetype', 'META-INF/container.xml', 'EPUB/content.opf', 'EPUB/nav.xhtml', 'EPUB/media/file0.jpg')) {
          if ($names -notcontains $required) { throw "EPUB 缺少必要資源：$required" }
        }
        $details += "EPUB 封裝與必要資源通過（$($names.Count) entries）。"
      } finally { $zip.Dispose() }
    }
    default { throw "未知工作流節點：$name" }
  }
  return $details
}

$started = [string]::IsNullOrWhiteSpace($FromStage)
foreach ($stage in $workflow.stages) {
  if (-not $started) {
    if ($stage.name -eq $FromStage) { $started = $true } else { continue }
  }

  $status = 'pass'
  $details = @()
  $errorMessage = ''
  try {
    foreach ($input in $stage.inputs) {
      if (-not (Test-Path -LiteralPath (Resolve-ProjectPath $input))) { throw "找不到輸入：$input" }
    }
    $details = @(Invoke-StageCheck $stage.name)
  } catch {
    $status = 'blocked'
    $errorMessage = $_.Exception.Message
  }

  $reportPath = Resolve-ProjectPath $stage.output
  New-Item -ItemType Directory -Force (Split-Path $reportPath) | Out-Null
  $lines = @(
    "# $($stage.name) 交接報告", '',
    ("- status: " + $status),
    "- inputs: $($stage.inputs -join ', ')",
    "- verified_at: $((Get-Date).ToString('yyyy-MM-ddTHH:mm:ssK'))", ''
  )
  if ($status -eq 'blocked') {
    $lines += '## 阻塞問題'
    $lines += "- $errorMessage"
  } else {
    $lines += '## 實際檢查'
    $details | ForEach-Object { $lines += "- $_" }
  }
  Set-Content -LiteralPath $reportPath -Value ($lines -join "`r`n") -Encoding utf8
  Write-Output "$($stage.name): $status -> $($stage.output)"
  if ($status -eq 'blocked') { exit 1 }
}
