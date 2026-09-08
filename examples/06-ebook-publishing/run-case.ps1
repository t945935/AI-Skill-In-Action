param(
  [string]$Version = '0.2.1-local',
  [string]$OutputRoot = 'dist'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Push-Location $projectRoot
try {
  & (Join-Path $projectRoot 'tools/package-release.ps1') -Version $Version -OutputRoot $OutputRoot
  if ($LASTEXITCODE -ne 0) { throw '電子書出版案例失敗' }
  & (Join-Path $PSScriptRoot 'verify-package.ps1') -Version $Version -OutputRoot $OutputRoot
  if ($LASTEXITCODE -ne 0) { throw '候選發行包驗收失敗' }
  Write-Output "case-complete: v$Version"
} finally {
  Pop-Location
}
