[CmdletBinding()]
param(
  [string]$SourceDir = (Join-Path (Split-Path -Parent $PSScriptRoot) 'source'),
  [string]$SiteDir = (Join-Path (Split-Path -Parent $PSScriptRoot) 'site')
)

$ErrorActionPreference = 'Stop'
$exampleRoot = Split-Path -Parent $PSScriptRoot
$buildScript = Join-Path $PSScriptRoot 'build-course.ps1'
$fixtureRoot = Join-Path $exampleRoot 'fixtures'

function Assert-Condition([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "[TEST] $Message" }
}

function Get-NormalizedPath([string]$PathValue) {
  return [System.IO.Path]::GetFullPath($PathValue).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Get-TreeSnapshot([string]$RootPath) {
  return @(
    Get-ChildItem -LiteralPath $RootPath -Recurse -File |
      Sort-Object FullName |
      ForEach-Object {
        $relativePath = $_.FullName.Substring($RootPath.Length).TrimStart('\', '/')
        "$relativePath|$((Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash)"
      }
  )
}

$sourceRoot = Get-NormalizedPath $SourceDir
$siteRoot = Get-NormalizedPath $SiteDir
Assert-Condition (Test-Path -LiteralPath $sourceRoot -PathType Container) '找不到主教材來源。'
Assert-Condition (Test-Path -LiteralPath $siteRoot -PathType Container) '找不到建置網站；請先執行 build-course.ps1。'

$sourceBefore = Get-TreeSnapshot $sourceRoot
$course = Get-Content -LiteralPath (Join-Path $sourceRoot 'course.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$lessons = @($course.lessons)
Assert-Condition ($lessons.Count -eq 2) '本案例必須維持兩課，搭配首頁共三個頁面。'

$htmlFiles = @(Get-ChildItem -LiteralPath $siteRoot -Filter '*.html' -File)
Assert-Condition ($htmlFiles.Count -eq 3) '網站應只有一個首頁與兩個課次頁面。'
Assert-Condition (Test-Path -LiteralPath (Join-Path $siteRoot 'index.html') -PathType Leaf) '缺少 index.html。'
Assert-Condition (Test-Path -LiteralPath (Join-Path $siteRoot 'assets/site.css') -PathType Leaf) '缺少本機 site.css。'
Assert-Condition (Test-Path -LiteralPath (Join-Path $siteRoot 'assets/app.js') -PathType Leaf) '缺少本機 app.js。'

foreach ($lesson in $lessons) {
  Assert-Condition (Test-Path -LiteralPath (Join-Path $siteRoot ($lesson.id + '.html')) -PathType Leaf) "缺少課次頁面：$($lesson.id).html"
}

foreach ($htmlFile in $htmlFiles) {
  $html = Get-Content -LiteralPath $htmlFile.FullName -Raw -Encoding UTF8
  Assert-Condition ($html -match '(?i)<!doctype html>') "$($htmlFile.Name) 缺少 HTML5 doctype。"
  Assert-Condition ($html -match '<html lang="zh-TW">') "$($htmlFile.Name) 缺少正確語言。"
  Assert-Condition ($html -match '<header\b' -and $html -match '<nav\b' -and $html -match '<main id="main"' -and $html -match '<footer\b') "$($htmlFile.Name) 缺少語意地標。"
  Assert-Condition ($html -match 'class="skip-link" href="#main"') "$($htmlFile.Name) 缺少跳到主要內容連結。"
  Assert-Condition ($html -notmatch '(?is)<script[^>]+src\s*=\s*["'']https?://') "$($htmlFile.Name) 載入遠端 JavaScript。"
  Assert-Condition ($html -notmatch '(?is)<link[^>]+href\s*=\s*["'']https?://') "$($htmlFile.Name) 載入遠端 CSS。"
  Assert-Condition ($html -notmatch '(?is)\son[a-z]+\s*=') "$($htmlFile.Name) 含有行內事件處理器。"

  foreach ($imageMatch in [regex]::Matches($html, '(?is)<img\b[^>]*>')) {
    Assert-Condition ($imageMatch.Value -match '(?is)\salt\s*=\s*["''][^"'']+["'']') "$($htmlFile.Name) 含有缺少替代文字的圖片。"
  }

  foreach ($linkMatch in [regex]::Matches($html, '(?i)href="(?<href>[^"]+)"')) {
    $href = $linkMatch.Groups['href'].Value
    if ($href.StartsWith('#') -or $href -match '^(?i:https?://|mailto:)') { continue }
    $target = ($href -split '#', 2)[0]
    if ($target.EndsWith('.html', [System.StringComparison]::OrdinalIgnoreCase)) {
      Assert-Condition (Test-Path -LiteralPath (Join-Path $siteRoot $target) -PathType Leaf) "$($htmlFile.Name) 有失效連結：$href"
    }
  }
}

$indexHtml = Get-Content -LiteralPath (Join-Path $siteRoot 'index.html') -Raw -Encoding UTF8
foreach ($lesson in $lessons) {
  Assert-Condition ($indexHtml -match [regex]::Escape(('href="{0}.html"' -f $lesson.id))) "首頁缺少 $($lesson.id) 的入口。"
  Assert-Condition ($indexHtml -match [regex]::Escape(('data-completion-state="{0}"' -f $lesson.id))) "首頁缺少 $($lesson.id) 的進度狀態。"
  $lessonHtml = Get-Content -LiteralPath (Join-Path $siteRoot ($lesson.id + '.html')) -Raw -Encoding UTF8
  Assert-Condition ($lessonHtml -match [regex]::Escape(('data-completion-id="{0}"' -f $lesson.id))) "$($lesson.id) 缺少完成狀態控制。"
  Assert-Condition ($lessonHtml -match 'class="lesson-pagination"') "$($lesson.id) 缺少上一課／下一課區域。"
  Assert-Condition ($lessonHtml -match 'aria-current="page"') "$($lesson.id) 未標示目前課次。"
}

$css = Get-Content -LiteralPath (Join-Path $siteRoot 'assets/site.css') -Raw -Encoding UTF8
$app = Get-Content -LiteralPath (Join-Path $siteRoot 'assets/app.js') -Raw -Encoding UTF8
Assert-Condition ($css -match ':focus-visible' -and $css -match 'outline:\s*[1-9]') 'CSS 缺少可見鍵盤焦點。'
Assert-Condition ($css -match '@media\s*\(max-width:' -and $css -match 'overflow-wrap:\s*anywhere') 'CSS 缺少響應式或長文字保護。'
Assert-Condition ($css -match '(?s)\.lesson-body pre\s*\{[^}]*overflow-x:\s*auto') 'CSS 缺少程式碼區塊的局部橫向捲動。'
Assert-Condition ($css -notmatch 'outline:\s*(0|none)') 'CSS 移除了焦點外框。'
Assert-Condition ($app -match 'localStorage' -and $app -match 'aria-pressed') 'JavaScript 缺少本機完成狀態功能。'
Assert-Condition ($app -match 'skip-link' -and $app -match 'main\.focus') 'JavaScript 缺少跳到主要內容後的焦點移動。'
Assert-Condition ($app -notmatch 'https?://') 'JavaScript 不應呼叫遠端資源。'

$sourceAfter = Get-TreeSnapshot $sourceRoot
Assert-Condition ((Compare-Object $sourceBefore $sourceAfter).Count -eq 0) '驗證期間主教材來源遭到修改。'

$fixtureBefore = Get-TreeSnapshot $fixtureRoot
$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('ai-skill-web-learning-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temporaryRoot | Out-Null

try {
  $completeOutput = Join-Path $temporaryRoot 'complete-site'
  & $buildScript -SourceDir (Join-Path $fixtureRoot 'complete') -OutputDir $completeOutput | Out-Null
  Assert-Condition (Test-Path -LiteralPath (Join-Path $completeOutput 'index.html') -PathType Leaf) '完整 fixture 未建立首頁。'
  Assert-Condition (Test-Path -LiteralPath (Join-Path $completeOutput 'fixture-lesson.html') -PathType Leaf) '完整 fixture 未建立課次頁。'

  $missingBlocked = $false
  $missingOutput = Join-Path $temporaryRoot 'missing-site'
  try {
    & $buildScript -SourceDir (Join-Path $fixtureRoot 'missing-objective') -OutputDir $missingOutput | Out-Null
  } catch {
    $missingBlocked = $_.Exception.Message.Contains('[CONTRACT]') -and $_.Exception.Message.Contains('objective')
  }
  Assert-Condition $missingBlocked '缺少 objective 的 fixture 沒有依契約阻塞。'
  Assert-Condition (-not (Test-Path -LiteralPath $missingOutput)) '被阻塞的缺漏 fixture 不應產生網站。'

  $unsafeFlagged = $false
  $unsafeOutput = Join-Path $temporaryRoot 'unsafe-site'
  try {
    & $buildScript -SourceDir (Join-Path $fixtureRoot 'unsafe-content') -OutputDir $unsafeOutput | Out-Null
  } catch {
    $unsafeFlagged = $_.Exception.Message.Contains('[SECURITY]') -and $_.Exception.Message.Contains('未執行')
  }
  Assert-Condition $unsafeFlagged '不安全 fixture 沒有被標示且停止。'
  Assert-Condition (-not (Test-Path -LiteralPath $unsafeOutput)) '不安全 fixture 不應產生網站。'
  Assert-Condition (-not (Test-Path -LiteralPath (Join-Path $fixtureRoot 'unsafe-content/unsafe-executed.txt'))) '不安全 fixture 產生了執行標記。'

  $fixtureAfter = Get-TreeSnapshot $fixtureRoot
  Assert-Condition ((Compare-Object $fixtureBefore $fixtureAfter).Count -eq 0) 'fixture 在測試期間遭到修改。'
} finally {
  $tempParent = Get-NormalizedPath ([System.IO.Path]::GetTempPath())
  $normalizedTemporaryRoot = Get-NormalizedPath $temporaryRoot
  $temporaryLeaf = Split-Path -Leaf $normalizedTemporaryRoot
  if ((Split-Path -Parent $normalizedTemporaryRoot) -eq $tempParent -and $temporaryLeaf.StartsWith('ai-skill-web-learning-test-') -and (Test-Path -LiteralPath $normalizedTemporaryRoot)) {
    Remove-Item -LiteralPath $normalizedTemporaryRoot -Recurse -Force
  }
}

Write-Output 'test-course: pass'
