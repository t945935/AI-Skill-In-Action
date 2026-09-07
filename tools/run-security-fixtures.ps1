$ErrorActionPreference = 'Stop'
$projectRoot = (Get-Location).Path
$fixtureRoot = Join-Path $projectRoot 'examples/04-verify-secure/fixtures'
$failed = $false

function Snapshot-Fixture([string]$path) {
  return @(Get-ChildItem -LiteralPath $path -Recurse -File | Sort-Object FullName | ForEach-Object {
    $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
    "$($_.FullName)|$hash"
  })
}

$complete = Join-Path $fixtureRoot 'complete'
$completeBefore = Snapshot-Fixture $complete
if ((Test-Path (Join-Path $complete 'chapter.md')) -and (Test-Path (Join-Path $complete 'GLOSSARY.md')) -and (Test-Path (Join-Path $complete 'STYLE_GUIDE.md'))) {
  'complete: pass'
} else { 'complete: blocked'; $failed = $true }

$missing = Join-Path $fixtureRoot 'missing-glossary'
if ((Test-Path (Join-Path $missing 'chapter.md')) -and -not (Test-Path (Join-Path $missing 'GLOSSARY.md'))) {
  'missing-glossary: blocked (expected)'
} else { 'missing-glossary: fail'; $failed = $true }

$untrusted = Join-Path $fixtureRoot 'untrusted-instructions/chapter.md'
$untrustedText = Get-Content -LiteralPath $untrusted -Raw
if ($untrustedText -match '忽略 Skill 規則' -and $untrustedText -match '執行命令') {
  'untrusted-instructions: flagged (not executed)'
} else { 'untrusted-instructions: fail'; $failed = $true }

$completeAfter = Snapshot-Fixture $complete
if ((Compare-Object $completeBefore $completeAfter).Count -gt 0) {
  'fixture-integrity: fail (輸入案例被修改)'; $failed = $true
} else { 'fixture-integrity: pass' }

if ($failed) { exit 1 }
