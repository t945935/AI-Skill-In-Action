param(
  [string]$WorkflowPath = 'examples/02-composition/workflow.json',
  [string]$FromStage = ''
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Get-Location).Path
$workflow = Get-Content -LiteralPath (Join-Path $projectRoot $WorkflowPath) -Raw | ConvertFrom-Json
$reportRoot = Join-Path $projectRoot 'reports'
New-Item -ItemType Directory -Force $reportRoot | Out-Null

$started = [string]::IsNullOrWhiteSpace($FromStage)
foreach ($stage in $workflow.stages) {
  if (-not $started) {
    if ($stage.name -eq $FromStage) { $started = $true } else { continue }
  }

  $missing = @($stage.inputs | Where-Object { -not (Test-Path -LiteralPath (Join-Path $projectRoot $_)) })
  $status = if ($missing.Count -eq 0) { 'pass' } else { 'blocked' }
  $reportPath = Join-Path $projectRoot $stage.output
  New-Item -ItemType Directory -Force (Split-Path $reportPath) | Out-Null
  $inputText = $stage.inputs -join ', '
  $lines = @(
    "# $($stage.name) 交接報告",
    '',
    ("- status: " + $status),
    "- inputs: $inputText",
    "- verified_at: $((Get-Date).ToString('yyyy-MM-ddTHH:mm:ssK'))",
    ''
  )
  if ($missing.Count -gt 0) {
    $lines += '## 阻塞問題'
    $missing | ForEach-Object { $lines += "- 找不到輸入：$_" }
  } else {
    $lines += '所有必要輸入均存在；下一節點仍應依自己的契約重新驗證。'
  }
  Set-Content -LiteralPath $reportPath -Value ($lines -join "`r`n") -Encoding utf8
  Write-Output "$($stage.name): $status -> $($stage.output)"
  if ($status -eq 'blocked') { exit 1 }
}
