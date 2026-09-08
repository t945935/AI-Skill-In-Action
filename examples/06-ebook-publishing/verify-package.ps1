param(
  [Parameter(Mandatory = $true)]
  [string]$Version,
  [string]$OutputRoot = 'dist'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$outputBase = if ([System.IO.Path]::IsPathRooted($OutputRoot)) {
  [System.IO.Path]::GetFullPath($OutputRoot)
} else {
  [System.IO.Path]::GetFullPath((Join-Path $projectRoot $OutputRoot))
}
$packageRoot = Join-Path $outputBase "v$Version"

if (-not (Test-Path -LiteralPath $packageRoot -PathType Container)) {
  throw "找不到候選發行包：$packageRoot"
}

$requiredFiles = @(
  'AI-Skill-In-Action.epub',
  'cover.jpg',
  'book.yaml',
  'store-listing.md',
  'release-gates.md',
  'RELEASE_STATUS.md',
  'manifest.txt',
  'SHA256SUMS.txt'
)
foreach ($name in $requiredFiles) {
  if (-not (Test-Path -LiteralPath (Join-Path $packageRoot $name) -PathType Leaf)) {
    throw "候選發行包缺少必要檔案：$name"
  }
}
Write-Output 'package-files: pass'

$packagePrefix = $packageRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
$summedFiles = @()
foreach ($line in (Get-Content -LiteralPath (Join-Path $packageRoot 'SHA256SUMS.txt'))) {
  if ([string]::IsNullOrWhiteSpace($line)) { continue }
  if ($line -notmatch '^([A-Fa-f0-9]{64})\s{2}(.+)$') {
    throw "SHA256SUMS.txt 格式錯誤：$line"
  }

  $expectedHash = $Matches[1].ToUpperInvariant()
  $relativePath = $Matches[2].Trim()
  if ($summedFiles -contains $relativePath) {
    throw "雜湊清單含重複路徑：$relativePath"
  }
  $summedFiles += $relativePath
  $targetPath = [System.IO.Path]::GetFullPath((Join-Path $packageRoot ($relativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)))
  if (-not $targetPath.StartsWith($packagePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "雜湊清單路徑超出候選發行包：$relativePath"
  }
  if (-not (Test-Path -LiteralPath $targetPath -PathType Leaf)) {
    throw "雜湊清單指向不存在的檔案：$relativePath"
  }

  $actualHash = (Get-FileHash -LiteralPath $targetPath -Algorithm SHA256).Hash.ToUpperInvariant()
  if ($actualHash -ne $expectedHash) {
    throw "SHA-256 不符：$relativePath"
  }
}
foreach ($name in $requiredFiles | Where-Object { $_ -ne 'SHA256SUMS.txt' }) {
  if ($summedFiles -notcontains $name) {
    throw "雜湊清單缺少必要檔案：$name"
  }
}
Write-Output 'checksum-verification: pass'

$manifestText = Get-Content -Raw -LiteralPath (Join-Path $packageRoot 'manifest.txt')
if ($manifestText -notmatch "(?m)^version=v$([regex]::Escape($Version))\r?$") {
  throw 'manifest 版本與要求版本不一致'
}
if ($manifestText -notmatch '(?m)^status=release-candidate\r?$') {
  throw 'manifest 未標示 release-candidate'
}
if ($manifestText -notmatch '(?m)^source_commit=[0-9a-fA-F]{40}\r?$') {
  throw 'manifest 缺少完整來源 commit'
}
foreach ($name in $requiredFiles | Where-Object { $_ -notin @('manifest.txt', 'SHA256SUMS.txt') }) {
  if ($manifestText -notmatch "(?m)^file=$([regex]::Escape($name))\|") {
    throw "manifest 缺少檔案紀錄：$name"
  }
}
Write-Output 'manifest-traceability: pass'

$statusText = Get-Content -Raw -LiteralPath (Join-Path $packageRoot 'RELEASE_STATUS.md')
if ($statusText -notmatch '(?m)^- Status: release-candidate\r?$') {
  throw 'RELEASE_STATUS.md 的候選狀態不正確'
}
if ($statusText -notmatch 'awaiting') {
  throw 'RELEASE_STATUS.md 未保留人工或外部驗證閘門'
}
Write-Output 'release-gate: awaiting-human-approval'
