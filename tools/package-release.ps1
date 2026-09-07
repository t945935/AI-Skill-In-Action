param(
  [string]$Version = '0.1.0',
  [string]$OutputRoot = 'dist'
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Get-Location).Path
$packageRoot = Join-Path $projectRoot (Join-Path $OutputRoot "v$Version")
if (Test-Path -LiteralPath $packageRoot) { throw "拒絕覆寫既有發行目錄：$packageRoot" }

$buildScript = Join-Path $projectRoot 'tools/build-manuscript.ps1'
$global:LASTEXITCODE = 0
& $buildScript | Out-Host
if ($LASTEXITCODE -ne 0) { throw '合併稿建置失敗' }

$pandoc = (Get-Command pandoc -ErrorAction SilentlyContinue).Source
if ([string]::IsNullOrWhiteSpace($pandoc)) { throw '找不到 Pandoc；請先安裝並加入 PATH' }
$epubPath = Join-Path $projectRoot 'output/AI-Skill-In-Action.epub'
$manuscriptPath = Join-Path $projectRoot 'output/manuscript.md'
$metadataPath = Join-Path $projectRoot 'metadata/book.yaml'
$cssPath = Join-Path $projectRoot 'styles/book.css'
$coverPath = Join-Path $projectRoot 'assets/cover/cover.jpg'
& $pandoc $manuscriptPath -o $epubPath `
  "--metadata-file=$metadataPath" `
  "--css=$cssPath" `
  "--epub-cover-image=$coverPath" `
  --toc --toc-depth=2 | Out-Host
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $epubPath)) { throw 'EPUB 建置失敗' }

$global:LASTEXITCODE = 0
& (Join-Path $projectRoot 'tools/run-workflow.ps1') | Out-Host
if ($LASTEXITCODE -ne 0) { throw '工作流驗證失敗' }
$global:LASTEXITCODE = 0
& (Join-Path $projectRoot 'tools/run-security-fixtures.ps1') | Out-Host
if ($LASTEXITCODE -ne 0) { throw '安全 fixture 驗證失敗' }

New-Item -ItemType Directory -Force $packageRoot | Out-Null
Copy-Item -LiteralPath $epubPath -Destination (Join-Path $packageRoot 'AI-Skill-In-Action.epub')
Copy-Item -LiteralPath (Join-Path $projectRoot 'assets/cover/cover.jpg') -Destination (Join-Path $packageRoot 'cover.jpg')
Copy-Item -LiteralPath (Join-Path $projectRoot 'metadata/book.yaml') -Destination (Join-Path $packageRoot 'book.yaml')
Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/store-listing.md') -Destination (Join-Path $packageRoot 'store-listing.md')
Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/release-gates.md') -Destination (Join-Path $packageRoot 'release-gates.md')

$commit = (& git -C $projectRoot rev-parse HEAD 2>$null).Trim()
$builtAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssK')
$status = @"
# Release status

- Version: v$Version
- Status: release-candidate
- Source commit: $commit
- Built at: $builtAt
- EPUBCheck: awaiting external validator
- Device reading test: awaiting human confirmation
- Author: Happy eBook Authors
- License, publisher, ISBN, price and territories: awaiting publisher confirmation
"@
Set-Content -LiteralPath (Join-Path $packageRoot 'RELEASE_STATUS.md') -Value $status -Encoding utf8

$manifest = @(
  "version=v$Version",
  'status=release-candidate',
  "source_commit=$commit",
  "built_at=$builtAt",
  'validator=tools/run-workflow.ps1; tools/run-security-fixtures.ps1',
  'known_limitations=EPUBCheck and device reading test require external confirmation',
  'commercial_fields=author confirmed; publisher/license/ISBN/price/territories pending'
)
Get-ChildItem -LiteralPath $packageRoot -File | Sort-Object Name | ForEach-Object {
  $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
  $manifest += "file=$($_.Name)|size=$($_.Length)|sha256=$hash"
}
Set-Content -LiteralPath (Join-Path $packageRoot 'manifest.txt') -Value ($manifest -join "`r`n") -Encoding utf8

$sums = Get-ChildItem -LiteralPath $packageRoot -File | Where-Object { $_.Name -notin @('SHA256SUMS.txt') } | Sort-Object Name | ForEach-Object {
  $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
  "$hash  $($_.Name)"
}
Set-Content -LiteralPath (Join-Path $packageRoot 'SHA256SUMS.txt') -Value ($sums -join "`r`n") -Encoding utf8
Write-Output "Packaged $packageRoot"
