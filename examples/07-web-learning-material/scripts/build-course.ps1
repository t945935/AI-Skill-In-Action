[CmdletBinding()]
param(
  [string]$SourceDir = (Join-Path (Split-Path -Parent $PSScriptRoot) 'source'),
  [string]$OutputDir = (Join-Path (Split-Path -Parent $PSScriptRoot) 'site'),
  [string]$TemplateDir = (Join-Path (Split-Path -Parent $PSScriptRoot) 'templates')
)

$ErrorActionPreference = 'Stop'

function Get-NormalizedPath([string]$PathValue) {
  $fullPath = [System.IO.Path]::GetFullPath($PathValue)
  $root = [System.IO.Path]::GetPathRoot($fullPath)
  if ($fullPath -eq $root) { return $fullPath }
  return $fullPath.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Test-IsSameOrChild([string]$Candidate, [string]$ParentPath) {
  if ($Candidate.Equals($ParentPath, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
  $prefix = $ParentPath
  if (-not $prefix.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
    $prefix += [System.IO.Path]::DirectorySeparatorChar
  }
  return $Candidate.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)
}

function Get-RequiredText($Object, [string]$PropertyName, [string]$Context) {
  $property = $Object.PSObject.Properties[$PropertyName]
  if ($null -eq $property -or [string]::IsNullOrWhiteSpace([string]$property.Value)) {
    throw "[CONTRACT] $Context 缺少 $PropertyName。"
  }
  return ([string]$property.Value).Trim()
}

function ConvertTo-HtmlText([string]$Value) {
  return [System.Net.WebUtility]::HtmlEncode($Value)
}

function Set-Utf8File([string]$PathValue, [string]$Content) {
  $utf8 = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($PathValue, $Content, $utf8)
}

function Get-TreeSnapshot([string]$RootPath) {
  return @(
    Get-ChildItem -LiteralPath $RootPath -Recurse -File |
      Sort-Object FullName |
      ForEach-Object {
        $relativePath = $_.FullName.Substring($RootPath.Length).TrimStart('\', '/')
        $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
        "$relativePath|$hash"
      }
  )
}

function Assert-SafeMarkdown([string]$Markdown, [string]$LessonPath, [string]$SourceRoot) {
  $dangerousElementPattern = '(?is)<\s*/?\s*(script|iframe|object|embed|style|link|meta)\b'
  $eventHandlerPattern = '(?is)<[^>]+\son[a-z]+\s*='

  if ($Markdown -match $dangerousElementPattern -or $Markdown -match $eventHandlerPattern -or $Markdown -match '(?i)javascript\s*:') {
    throw "[SECURITY] $LessonPath 含有可執行或可導向程式碼的內容，已停止且未執行。"
  }

  if ($Markdown -match '(?m)!\[\s*\]\(') {
    throw "[CONTRACT] $LessonPath 含有缺少替代文字的圖片。"
  }
  if ($Markdown -match '!\[[^\]]+\]\[[^\]]*\]') {
    throw "[CONTRACT] $LessonPath 使用參照式圖片；本範例只接受 media/ 下的行內圖片路徑。"
  }

  $imageMatches = [regex]::Matches($Markdown, '!\[(?<alt>[^\]]*)\]\((?<target>[^)\s]+)')
  foreach ($imageMatch in $imageMatches) {
    $alt = $imageMatch.Groups['alt'].Value.Trim()
    $target = $imageMatch.Groups['target'].Value.Trim('<', '>')
    if ([string]::IsNullOrWhiteSpace($alt)) {
      throw "[CONTRACT] $LessonPath 含有缺少替代文字的圖片。"
    }
    if ($target -match '^(?i:https?:|data:|javascript:|//)') {
      throw "[SECURITY] $LessonPath 的圖片必須使用本機相對路徑。"
    }
    $normalizedTarget = $target.Replace('\', '/')
    if (-not $normalizedTarget.StartsWith('media/', [System.StringComparison]::OrdinalIgnoreCase)) {
      throw "[CONTRACT] $LessonPath 的圖片必須放在 source/media/，並以 media/檔名 引用。"
    }
    $imagePath = Get-NormalizedPath (Join-Path $SourceRoot $normalizedTarget)
    if (-not (Test-IsSameOrChild $imagePath (Join-Path $SourceRoot 'media')) -or -not (Test-Path -LiteralPath $imagePath -PathType Leaf)) {
      throw "[CONTRACT] $LessonPath 引用不存在或超出 media/ 的圖片：$target"
    }
  }
}

function Expand-Template([string]$Template, [hashtable]$Values) {
  $result = $Template
  foreach ($key in $Values.Keys) {
    $result = $result.Replace("{{$key}}", [string]$Values[$key])
  }
  if ($result -match '\{\{[A-Z0-9_]+\}\}') {
    throw "[BUILD] 版型仍有未替換的欄位：$($Matches[0])"
  }
  return $result
}

$sourceRoot = Get-NormalizedPath $SourceDir
$templateRoot = Get-NormalizedPath $TemplateDir
$outputRoot = Get-NormalizedPath $OutputDir
$outputPathRoot = [System.IO.Path]::GetPathRoot($outputRoot)

if (-not (Test-Path -LiteralPath $sourceRoot -PathType Container)) {
  throw "[CONTRACT] 找不到教材來源目錄：$sourceRoot"
}
if (-not (Test-Path -LiteralPath $templateRoot -PathType Container)) {
  throw "[CONTRACT] 找不到版型目錄：$templateRoot"
}
if ($outputRoot.Equals($outputPathRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
  throw '[SAFETY] 輸出目錄不可為磁碟根目錄。'
}
if ((Test-IsSameOrChild $outputRoot $sourceRoot) -or (Test-IsSameOrChild $sourceRoot $outputRoot)) {
  throw '[SAFETY] 輸出目錄與教材來源不可相同或互相包含。'
}
if ((Test-IsSameOrChild $outputRoot $templateRoot) -or (Test-IsSameOrChild $templateRoot $outputRoot)) {
  throw '[SAFETY] 輸出目錄與版型目錄不可相同或互相包含。'
}
if (Test-Path -LiteralPath $outputRoot -PathType Leaf) {
  throw "[SAFETY] 輸出路徑已被檔案占用：$outputRoot"
}
if (Test-Path -LiteralPath $outputRoot) {
  $outputItem = Get-Item -LiteralPath $outputRoot -Force
  if ($outputItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
    throw '[SAFETY] 輸出目錄不可為符號連結或重新解析點。'
  }
  if (-not (Test-Path -LiteralPath (Join-Path $outputRoot '.web-learning-output') -PathType Leaf)) {
    throw '[SAFETY] 既有輸出目錄缺少管理標記，拒絕覆寫。請改用新的輸出目錄。'
  }
}

$requiredTemplates = @('index.html', 'page.html', 'site.css', 'app.js')
foreach ($templateName in $requiredTemplates) {
  if (-not (Test-Path -LiteralPath (Join-Path $templateRoot $templateName) -PathType Leaf)) {
    throw "[CONTRACT] 缺少版型檔案：$templateName"
  }
}

$pandocCommand = Get-Command pandoc -ErrorAction SilentlyContinue
if ($null -eq $pandocCommand) {
  throw '[BUILD] 找不到 Pandoc；請先執行 pandoc --version 確認安裝。'
}

$courseFile = Join-Path $sourceRoot 'course.json'
if (-not (Test-Path -LiteralPath $courseFile -PathType Leaf)) {
  throw '[CONTRACT] source/course.json 不存在。'
}

try {
  $course = Get-Content -LiteralPath $courseFile -Raw -Encoding UTF8 | ConvertFrom-Json
} catch {
  throw "[CONTRACT] course.json 不是有效 JSON：$($_.Exception.Message)"
}

$courseId = Get-RequiredText $course 'id' 'course.json'
$courseTitle = Get-RequiredText $course 'title' 'course.json'
$courseDescription = Get-RequiredText $course 'description' 'course.json'
$courseLanguage = Get-RequiredText $course 'language' 'course.json'
if ($courseId -notmatch '^[a-z0-9][a-z0-9-]*$') {
  throw '[CONTRACT] course.json 的 id 只能使用小寫英文字母、數字與連字號。'
}

$lessonProperty = $course.PSObject.Properties['lessons']
$lessonItems = if ($null -eq $lessonProperty) { @() } else { @($lessonProperty.Value) }
if ($lessonItems.Count -eq 0) {
  throw '[CONTRACT] course.json 至少需要一個課次。'
}

$sourceBefore = Get-TreeSnapshot $sourceRoot
$seenIds = @{}
$seenFiles = @{}
$lessons = @()

for ($index = 0; $index -lt $lessonItems.Count; $index++) {
  $item = $lessonItems[$index]
  $context = "lessons[$index]"
  $lessonId = Get-RequiredText $item 'id' $context
  $lessonTitle = Get-RequiredText $item 'title' $context
  $lessonFile = Get-RequiredText $item 'file' $context
  $lessonObjective = Get-RequiredText $item 'objective' $context

  if ($lessonId -notmatch '^[a-z0-9][a-z0-9-]*$') {
    throw "[CONTRACT] $context 的 id 只能使用小寫英文字母、數字與連字號。"
  }
  if ($seenIds.ContainsKey($lessonId)) {
    throw "[CONTRACT] 課次 id 重複：$lessonId"
  }
  $seenIds[$lessonId] = $true

  if ([System.IO.Path]::IsPathRooted($lessonFile) -or [System.IO.Path]::GetExtension($lessonFile) -ne '.md') {
    throw "[CONTRACT] $context 的 file 必須是來源目錄內的相對 Markdown 路徑。"
  }
  $lessonPath = Get-NormalizedPath (Join-Path $sourceRoot $lessonFile)
  if (-not (Test-IsSameOrChild $lessonPath $sourceRoot) -or -not (Test-Path -LiteralPath $lessonPath -PathType Leaf)) {
    throw "[CONTRACT] 找不到或不可使用的課次檔案：$lessonFile"
  }
  if ($seenFiles.ContainsKey($lessonPath)) {
    throw "[CONTRACT] 課次檔案重複：$lessonFile"
  }
  $seenFiles[$lessonPath] = $true

  $markdown = Get-Content -LiteralPath $lessonPath -Raw -Encoding UTF8
  Assert-SafeMarkdown $markdown $lessonFile $sourceRoot
  $lessons += [pscustomobject]@{
    Id = $lessonId
    Title = $lessonTitle
    File = $lessonFile
    Path = $lessonPath
    Objective = $lessonObjective
    Markdown = $markdown
    Number = $index + 1
  }
}

$indexTemplate = Get-Content -LiteralPath (Join-Path $templateRoot 'index.html') -Raw -Encoding UTF8
$pageTemplate = Get-Content -LiteralPath (Join-Path $templateRoot 'page.html') -Raw -Encoding UTF8
$siteCss = Get-Content -LiteralPath (Join-Path $templateRoot 'site.css') -Raw -Encoding UTF8
$appJs = Get-Content -LiteralPath (Join-Path $templateRoot 'app.js') -Raw -Encoding UTF8

$outputParent = Split-Path -Parent $outputRoot
if (-not (Test-Path -LiteralPath $outputParent -PathType Container)) {
  New-Item -ItemType Directory -Path $outputParent -Force | Out-Null
}
$outputLeaf = Split-Path -Leaf $outputRoot
$staging = Join-Path $outputParent ('.' + $outputLeaf + '.staging-' + [guid]::NewGuid().ToString('N'))
$backup = $null

try {
  New-Item -ItemType Directory -Path $staging | Out-Null
  $assetDir = Join-Path $staging 'assets'
  New-Item -ItemType Directory -Path $assetDir | Out-Null
  Set-Utf8File (Join-Path $assetDir 'site.css') $siteCss
  Set-Utf8File (Join-Path $assetDir 'app.js') $appJs
  Set-Utf8File (Join-Path $staging '.web-learning-output') "managed-by=web-learning-material-workflow`n"

  $mediaDir = Join-Path $sourceRoot 'media'
  if (Test-Path -LiteralPath $mediaDir -PathType Container) {
    Copy-Item -LiteralPath $mediaDir -Destination (Join-Path $staging 'media') -Recurse
  }

  $navLines = @()
  $cardLines = @()
  foreach ($lesson in $lessons) {
    $idText = ConvertTo-HtmlText $lesson.Id
    $titleText = ConvertTo-HtmlText $lesson.Title
    $objectiveText = ConvertTo-HtmlText $lesson.Objective
    $navLines += ('        <li><a href="{0}.html">第 {1} 課：{2}</a></li>' -f $idText, $lesson.Number, $titleText)
    $cardLines += @(
      '        <li class="lesson-card">'
      ('          <p class="eyebrow">第 {0} 課</p>' -f $lesson.Number)
      ('          <h3>{0}</h3>' -f $titleText)
      ('          <p>{0}</p>' -f $objectiveText)
      ('          <p class="completion-state" data-completion-state="{0}">尚未完成</p>' -f $idText)
      ('          <a href="{0}.html">開始本課<span class="visually-hidden">：{1}</span></a>' -f $idText, $titleText)
      '        </li>'
    )
  }

  $indexHtml = Expand-Template $indexTemplate @{
    LANG = ConvertTo-HtmlText $courseLanguage
    COURSE_ID = ConvertTo-HtmlText $courseId
    COURSE_TITLE = ConvertTo-HtmlText $courseTitle
    COURSE_DESCRIPTION = ConvertTo-HtmlText $courseDescription
    LESSON_COUNT = $lessons.Count
    LESSON_NAV = $navLines -join [Environment]::NewLine
    LESSON_CARDS = $cardLines -join [Environment]::NewLine
  }
  Set-Utf8File (Join-Path $staging 'index.html') $indexHtml

  for ($index = 0; $index -lt $lessons.Count; $index++) {
    $lesson = $lessons[$index]
    $bodyFile = Join-Path $staging ('.body-' + $lesson.Id + '.html')
    $pandocMessages = @(& $pandocCommand.Source $lesson.Path '--from=gfm-raw_html' '--to=html5' '--wrap=none' "--output=$bodyFile" 2>&1)
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $bodyFile -PathType Leaf)) {
      throw "[BUILD] Pandoc 無法轉換 $($lesson.File)：$($pandocMessages -join ' ')"
    }
    $lessonBody = Get-Content -LiteralPath $bodyFile -Raw -Encoding UTF8
    Remove-Item -LiteralPath $bodyFile -Force

    $pageNavLines = @()
    foreach ($navLesson in $lessons) {
      $current = if ($navLesson.Id -eq $lesson.Id) { ' aria-current="page"' } else { '' }
      $pageNavLines += ('        <li><a href="{0}.html"{1}>第 {2} 課：{3}</a></li>' -f (ConvertTo-HtmlText $navLesson.Id), $current, $navLesson.Number, (ConvertTo-HtmlText $navLesson.Title))
    }

    if ($index -gt 0) {
      $previous = $lessons[$index - 1]
      $previousLink = '<a class="previous-link" href="{0}.html">← 上一課：{1}</a>' -f (ConvertTo-HtmlText $previous.Id), (ConvertTo-HtmlText $previous.Title)
    } else {
      $previousLink = '<span class="pagination-disabled" aria-disabled="true">← 已是第一課</span>'
    }
    if ($index -lt ($lessons.Count - 1)) {
      $next = $lessons[$index + 1]
      $nextLink = '<a class="next-link" href="{0}.html">下一課：{1} →</a>' -f (ConvertTo-HtmlText $next.Id), (ConvertTo-HtmlText $next.Title)
    } else {
      $nextLink = '<a class="next-link" href="index.html">完成課程，查看總進度 →</a>'
    }

    $pageHtml = Expand-Template $pageTemplate @{
      LANG = ConvertTo-HtmlText $courseLanguage
      COURSE_ID = ConvertTo-HtmlText $courseId
      COURSE_TITLE = ConvertTo-HtmlText $courseTitle
      LESSON_ID = ConvertTo-HtmlText $lesson.Id
      LESSON_TITLE = ConvertTo-HtmlText $lesson.Title
      LESSON_OBJECTIVE = ConvertTo-HtmlText $lesson.Objective
      LESSON_NUMBER = $lesson.Number
      LESSON_COUNT = $lessons.Count
      LESSON_NAV = $pageNavLines -join [Environment]::NewLine
      LESSON_BODY = $lessonBody
      PREVIOUS_LINK = $previousLink
      NEXT_LINK = $nextLink
    }
    Set-Utf8File (Join-Path $staging ($lesson.Id + '.html')) $pageHtml
  }

  $sourceAfter = Get-TreeSnapshot $sourceRoot
  if ((Compare-Object $sourceBefore $sourceAfter).Count -ne 0) {
    throw '[SAFETY] 建置期間教材來源發生變更，已停止交換輸出。'
  }

  if (Test-Path -LiteralPath $outputRoot -PathType Container) {
    $backup = Join-Path $outputParent ('.' + $outputLeaf + '.backup-' + [guid]::NewGuid().ToString('N'))
    Move-Item -LiteralPath $outputRoot -Destination $backup
  }
  Move-Item -LiteralPath $staging -Destination $outputRoot
  $staging = $null
  if ($null -ne $backup -and (Test-Path -LiteralPath $backup -PathType Container)) {
    Remove-Item -LiteralPath $backup -Recurse -Force
    $backup = $null
  }
} catch {
  if ($null -ne $staging -and (Test-Path -LiteralPath $staging)) {
    Remove-Item -LiteralPath $staging -Recurse -Force
  }
  if ($null -ne $backup -and (Test-Path -LiteralPath $backup -PathType Container)) {
    if (Test-Path -LiteralPath $outputRoot -PathType Container) {
      Remove-Item -LiteralPath $outputRoot -Recurse -Force
    }
    Move-Item -LiteralPath $backup -Destination $outputRoot
  }
  throw
}

Write-Output "site-build: $outputRoot"
