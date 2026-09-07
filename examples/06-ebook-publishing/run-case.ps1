$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$required = @(
  'manuscript/frontmatter.md',
  'metadata/book.yaml',
  'assets/cover/cover.jpg',
  'tools/build-manuscript.ps1'
)
$missing = @($required | Where-Object { -not (Test-Path -LiteralPath (Join-Path $projectRoot $_)) })
if ($missing.Count -gt 0) { throw "缺少必要輸入：$($missing -join ', ')" }

& (Join-Path $projectRoot 'tools/build-manuscript.ps1')
$epub = Join-Path $projectRoot 'output/AI-Skill-In-Action.epub'
if (-not (Test-Path -LiteralPath $epub)) { throw 'EPUB 建置失敗：找不到 output/AI-Skill-In-Action.epub' }
Write-Output "ready-for-validation: $epub"
