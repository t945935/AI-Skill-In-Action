param(
  [string]$Version = '0.1.0',
  [string]$OutputRoot = 'dist'
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Get-Location).Path
$sourceRoot = Join-Path $projectRoot 'examples/03-build-skill'
$packageRoot = Join-Path $projectRoot (Join-Path $OutputRoot "book-chapter-review-v$Version")
if (Test-Path -LiteralPath $packageRoot) { throw "拒絕覆寫既有發行目錄：$packageRoot" }

New-Item -ItemType Directory -Force $packageRoot | Out-Null
Copy-Item -Recurse -Force (Join-Path $sourceRoot '*') $packageRoot
$manifest = @(
  "name=book-chapter-review",
  "version=$Version",
  "source=examples/03-build-skill"
)
Get-ChildItem -LiteralPath $packageRoot -File -Recurse | Sort-Object FullName | ForEach-Object {
  $relative = $_.FullName.Substring($packageRoot.Length + 1).Replace('\','/')
  $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
  $manifest += "file=$relative|size=$($_.Length)|sha256=$hash"
}
Set-Content -LiteralPath (Join-Path $packageRoot 'manifest.txt') -Value ($manifest -join "`r`n") -Encoding utf8
Write-Output "Packaged $packageRoot"
