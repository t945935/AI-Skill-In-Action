param(
  [string]$Version = '0.2.0-local'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Push-Location $projectRoot
try {
  & (Join-Path $projectRoot 'tools/package-release.ps1') -Version $Version
  if ($LASTEXITCODE -ne 0) { throw '電子書出版案例失敗' }
  Write-Output "case-complete: dist/v$Version/"
} finally {
  Pop-Location
}
