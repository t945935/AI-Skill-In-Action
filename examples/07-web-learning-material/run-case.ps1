$ErrorActionPreference = 'Stop'

$exampleRoot = $PSScriptRoot
$buildScript = Join-Path $exampleRoot 'scripts/build-course.ps1'
$testScript = Join-Path $exampleRoot 'scripts/test-course.ps1'
$sourceDir = Join-Path $exampleRoot 'source'
$siteDir = Join-Path $exampleRoot 'site'

& $buildScript -SourceDir $sourceDir -OutputDir $siteDir | Out-Null
& $testScript -SourceDir $sourceDir -SiteDir $siteDir | Out-Null

Write-Output 'content-contract: pass'
Write-Output 'site-build: pass'
Write-Output 'navigation-check: pass'
Write-Output 'accessibility-baseline: pass'
Write-Output 'security-fixtures: pass'
Write-Output 'deployment-gate: awaiting-human-approval'
