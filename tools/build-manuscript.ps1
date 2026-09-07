$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$chapterRoot = Join-Path $projectRoot 'manuscript\chapters'
$appendixRoot = Join-Path $projectRoot 'manuscript\appendices'
$frontmatter = Join-Path $projectRoot 'manuscript\frontmatter.md'
$outputPath = Join-Path $projectRoot 'output\manuscript.md'

$parts = @()
$parts += Get-Content -LiteralPath $frontmatter -Raw
$parts += Get-ChildItem -LiteralPath $chapterRoot -Filter '*.md' | Sort-Object Name | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw }
$parts += Get-ChildItem -LiteralPath $appendixRoot -Filter '*.md' | Sort-Object Name | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw }

$merged = ($parts -join "`r`n`r`n") + "`r`n"
Set-Content -LiteralPath $outputPath -Value $merged -Encoding utf8
Write-Output "Built $outputPath"
