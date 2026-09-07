$ErrorActionPreference = 'Stop'

$skillRoot = Join-Path $env:USERPROFILE '.codex\skills'
if (-not (Test-Path -LiteralPath $skillRoot)) {
  Write-Output "找不到本機 Skill 目錄：$skillRoot"
  Write-Output '請確認宿主的安裝方式，或先完成 GETTING_STARTED.md 的安裝步驟。'
  exit 0
}

Get-ChildItem -LiteralPath $skillRoot -Directory |
  Sort-Object Name |
  Select-Object -ExpandProperty Name
