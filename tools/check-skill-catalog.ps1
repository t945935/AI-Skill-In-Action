$ErrorActionPreference = 'Stop'
$projectRoot = (Get-Location).Path
$catalogRoot = Join-Path $projectRoot 'examples/skills'
$catalog = Join-Path $catalogRoot 'skill-catalog.md'
$template = Join-Path $catalogRoot 'skill-card-template.md'
if (-not (Test-Path -LiteralPath $catalog)) { throw '找不到 skill-catalog.md' }
if (-not (Test-Path -LiteralPath $template)) { throw '找不到 skill-card-template.md' }

$required = @('用途', '觸發', '輸入', '輸出', '驗收', '限制', '來源')
$failed = @()
foreach ($dir in (Get-ChildItem -LiteralPath $catalogRoot -Directory)) {
  $readme = Join-Path $dir.FullName 'README.md'
  if (-not (Test-Path -LiteralPath $readme)) { $failed += "$($dir.Name): 缺少 README.md"; continue }
  $text = Get-Content -LiteralPath $readme -Raw
  foreach ($field in $required) {
    if ($text -notmatch [regex]::Escape($field)) { $failed += "$($dir.Name): 缺少欄位 $field" }
  }
}
if ($failed.Count -gt 0) { $failed | ForEach-Object { Write-Error $_ }; exit 1 }
Write-Output "skill-catalog: pass ($((Get-ChildItem -LiteralPath $catalogRoot -Directory).Count) cards)"
