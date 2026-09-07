[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [ValidatePattern('^[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?$')]
  [string]$Version,
  [string]$SiteDir = (Join-Path (Split-Path -Parent $PSScriptRoot) 'site'),
  [string]$OutputRoot = (Join-Path (Split-Path -Parent $PSScriptRoot) 'dist')
)

$ErrorActionPreference = 'Stop'
$exampleRoot = Split-Path -Parent $PSScriptRoot
$testScript = Join-Path $PSScriptRoot 'test-course.ps1'

function Get-NormalizedPath([string]$PathValue) {
  $fullPath = [System.IO.Path]::GetFullPath($PathValue)
  $root = [System.IO.Path]::GetPathRoot($fullPath)
  if ($fullPath -eq $root) { return $fullPath }
  return $fullPath.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Set-Utf8File([string]$PathValue, [string]$Content) {
  $utf8 = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($PathValue, $Content, $utf8)
}

$siteRoot = Get-NormalizedPath $SiteDir
$releaseRoot = Get-NormalizedPath $OutputRoot
$releasePathRoot = [System.IO.Path]::GetPathRoot($releaseRoot)
if ($releaseRoot -eq $releasePathRoot) { throw '[SAFETY] 發行根目錄不可為磁碟根目錄。' }
if (-not (Test-Path -LiteralPath $siteRoot -PathType Container)) { throw '[PACKAGE] 找不到 site/；請先執行 run-case.ps1。' }
if (-not (Test-Path -LiteralPath (Join-Path $siteRoot '.web-learning-output') -PathType Leaf)) { throw '[SAFETY] site/ 缺少建置管理標記。' }
$qaReport = Join-Path $exampleRoot 'browser-qa.md'
if (-not (Test-Path -LiteralPath $qaReport -PathType Leaf)) { throw '[PACKAGE] 缺少 browser-qa.md；請先完成瀏覽器走查。' }

& $testScript -SourceDir (Join-Path $exampleRoot 'source') -SiteDir $siteRoot | Out-Null
if ($LASTEXITCODE -ne 0) { throw '[PACKAGE] 網頁教材驗證未通過。' }

if (-not (Test-Path -LiteralPath $releaseRoot -PathType Container)) {
  New-Item -ItemType Directory -Path $releaseRoot -Force | Out-Null
}
$packageRoot = Join-Path $releaseRoot ("v$Version")
if (Test-Path -LiteralPath $packageRoot) { throw "[PACKAGE] 拒絕覆寫既有版本：$packageRoot" }

$staging = Join-Path $releaseRoot ('.staging-v' + $Version + '-' + [guid]::NewGuid().ToString('N'))
try {
  New-Item -ItemType Directory -Path $staging | Out-Null
  Copy-Item -LiteralPath $siteRoot -Destination (Join-Path $staging 'site') -Recurse
  Copy-Item -LiteralPath $qaReport -Destination (Join-Path $staging 'browser-qa.md')

  $commit = (& git -C $exampleRoot rev-parse HEAD 2>$null)
  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace([string]$commit)) { $commit = 'not-recorded' }
  $commitText = ([string]$commit).Trim()
  $status = @(
    '# Web learning material release status',
    '',
    "- Version: v$Version",
    '- Status: deployment-candidate',
    "- Source commit: $commitText",
    '- Deployment gate: awaiting-human-approval',
    '- Required confirmation: URL, public scope, asset rights, privacy settings and rollback plan'
  ) -join "`n"
  Set-Utf8File (Join-Path $staging 'RELEASE_STATUS.md') ($status + "`n")

  $manifestLines = @(
    "version=v$Version",
    'status=deployment-candidate',
    "source_commit=$commitText",
    'deployment_gate=awaiting-human-approval'
  )
  Get-ChildItem -LiteralPath $staging -Recurse -File | Sort-Object FullName | ForEach-Object {
    $relative = $_.FullName.Substring($staging.Length).TrimStart('\', '/').Replace('\', '/')
    $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
    $manifestLines += "file=$relative|size=$($_.Length)|sha256=$hash"
  }
  Set-Utf8File (Join-Path $staging 'manifest.txt') (($manifestLines -join "`n") + "`n")

  $sumLines = Get-ChildItem -LiteralPath $staging -Recurse -File | Where-Object { $_.Name -ne 'SHA256SUMS.txt' } | Sort-Object FullName | ForEach-Object {
    $relative = $_.FullName.Substring($staging.Length).TrimStart('\', '/').Replace('\', '/')
    "$((Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash)  $relative"
  }
  Set-Utf8File (Join-Path $staging 'SHA256SUMS.txt') (($sumLines -join "`n") + "`n")
  Move-Item -LiteralPath $staging -Destination $packageRoot
  $staging = $null
} finally {
  if ($null -ne $staging -and (Test-Path -LiteralPath $staging)) {
    Remove-Item -LiteralPath $staging -Recurse -Force
  }
}

Write-Output "course-package: $packageRoot"
