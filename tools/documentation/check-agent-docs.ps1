# Из корня проекта: powershell -NoProfile -ExecutionPolicy Bypass -File tools/documentation/check-agent-docs.ps1
[CmdletBinding()]
param([string] $ProjectRoot)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
if (-not $ProjectRoot) { $ProjectRoot = Join-Path $PSScriptRoot '../..' }
$ProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
$claudeDir = Join-Path $ProjectRoot '.claude'
$problems = [System.Collections.Generic.List[string]]::new()
$linkCount = 0
$ruleCount = 0

# Правила без paths Claude Code грузит в каждую сессию; третье такое требует решения в decisions/agent-docs.md.
$UnconditionalRules = @('workflow.md', 'code-style.md')
# Исходники заказчика (ТЗ): не правятся и ссылками не проверяются. Пример: @('docs/tz-prototype.md')
$ExcludedDocs = @()

function Read-Doc([string] $path) {
	return [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8).Replace("`r`n", "`n").Trim()
}

function Relative([string] $path) {
	return $path.Substring($ProjectRoot.Length).TrimStart('\', '/').Replace('\', '/')
}

function Without-Fences([string] $text) {
	return [regex]::Replace($text, '(?ms)^\s*(`{3,}|~{3,})[^\n]*\n.*?^\s*\1\s*$', '')
}

function Get-Anchors([string] $text) {
	$anchors = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
	$seen = @{}
	foreach ($heading in [regex]::Matches((Without-Fences $text), '(?m)^#{1,6}\s+(.+?)\s*#*\s*$')) {
		$slug = $heading.Groups[1].Value.ToLowerInvariant()
		$slug = [regex]::Replace($slug, '\[([^\]]+)\]\([^)]*\)', '$1')
		$slug = [regex]::Replace($slug, '[^\p{L}\p{N}_\-\s]', '')
		$slug = [regex]::Replace($slug, '\s', '-')
		if ($seen.ContainsKey($slug)) {
			$seen[$slug]++
			[void] $anchors.Add("$slug-$($seen[$slug])")
		} else {
			$seen[$slug] = 0
			[void] $anchors.Add($slug)
		}
	}
	return ,$anchors
}

function Test-Reference([string] $docPath, [string] $rawTarget, [bool] $fromRoot) {
	$target = $rawTarget.Trim()
	if ($target.StartsWith('<')) { $target = ($target -split '>', 2)[0].Substring(1) }
	$target = [regex]::Replace($target, '\s+["''].*["'']\s*$', '')
	if (-not $target -or $target -match '^(?:[a-zA-Z][a-zA-Z0-9+.-]*:|//)') { return }
	if ($target -match '[*?{}]' -or $target -match '<[^>]+>|\.\.\.|…') { return }
	$parts = $target -split '#', 2
	$fileTarget = [uri]::UnescapeDataString($parts[0])
	$anchor = if ($parts.Count -gt 1) { [uri]::UnescapeDataString($parts[1]) } else { '' }
	$script:linkCount++
	if (-not $fileTarget) {
		$resolved = $docPath
	} elseif ($fromRoot) {
		$resolved = Join-Path $ProjectRoot $fileTarget
	} else {
		$resolved = Join-Path (Split-Path -Parent $docPath) $fileTarget
	}
	if (-not (Test-Path -LiteralPath $resolved)) {
		$script:problems.Add("Битая ссылка: $(Relative $docPath) -> $target")
		return
	}
	if ($anchor -and (Test-Path -LiteralPath $resolved -PathType Leaf) -and [System.IO.Path]::GetExtension($resolved) -eq '.md') {
		if (-not (Get-Anchors (Read-Doc $resolved)).Contains($anchor)) {
			$script:problems.Add("Нет anchor: $(Relative $docPath) -> $target")
		}
	}
}

# Обязательный состав
$required = @(
	'CLAUDE.md', '.claude/README.md', '.claude/decisions.md', '.claude/pitfalls/README.md',
	'.claude/docs/systems/README.md', '.claude/docs/concept.md', '.claude/docs/debts.md',
	'.claude/docs/roadmap-to-prototype.md', '.claude/docs/milestones-done.md',
	'.claude/hooks/roblox-mcp-reminders.json', '.claude/hooks/roblox-mcp-reminder.py', '.claude/settings.json'
)
foreach ($file in $required) {
	if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $file) -PathType Leaf)) { $problems.Add("Отсутствует файл: $file") }
}

# Правила: индекс в CLAUDE.md и paths
$rootText = Read-Doc (Join-Path $ProjectRoot 'CLAUDE.md')
foreach ($rule in (Get-ChildItem -LiteralPath (Join-Path $claudeDir 'rules') -Filter '*.md' -File -Recurse)) {
	$ruleCount++
	$relativeRule = $rule.FullName.Substring($claudeDir.Length + 1).Replace('\', '/')
	if ($rootText -notmatch [regex]::Escape(".claude/$relativeRule")) { $problems.Add("Правило не в таблице CLAUDE.md: $relativeRule") }
	$header = [regex]::Match((Read-Doc $rule.FullName), '(?s)^---\n(.*?)\n---(?:\n|$)')
	$pathsLine = if ($header.Success) { [regex]::Match($header.Groups[1].Value, '(?m)^paths:\s*(\[.*\])\s*$') } else { $null }
	if ($rule.Name -in $UnconditionalRules) {
		if ($header.Success) { $problems.Add("Безусловное правило не должно иметь frontmatter: $relativeRule") }
		continue
	}
	if (-not $pathsLine -or -not $pathsLine.Success) {
		$problems.Add("Правило без paths (третье безусловное требует решения): $relativeRule")
		continue
	}
	$globs = [regex]::Matches($pathsLine.Groups[1].Value, '"([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
	if (-not $globs) { $problems.Add("Пустой paths: $relativeRule") }
	foreach ($glob in $globs) {
		$literal = ($glob -split '[*?]', 2)[0]
		if ($literal -and -not (Test-Path -LiteralPath (Join-Path $ProjectRoot $literal))) {
			$problems.Add("paths указывает на несуществующее: $relativeRule -> $glob")
		}
	}
}

# Индексы разделов
$indexes = @(
	@('decisions', 'decisions.md'),
	@('pitfalls', 'pitfalls/README.md'),
	@('docs/systems', 'docs/systems/README.md')
)
foreach ($spec in $indexes) {
	$folder = Join-Path $claudeDir $spec[0]
	$indexPath = Join-Path $claudeDir $spec[1]
	if (-not (Test-Path -LiteralPath $folder -PathType Container) -or -not (Test-Path -LiteralPath $indexPath -PathType Leaf)) { continue }
	$indexText = Read-Doc $indexPath
	foreach ($topic in (Get-ChildItem -LiteralPath $folder -Filter '*.md' -File)) {
		if ($topic.Name -eq 'README.md') { continue }
		if ($indexText -notmatch [regex]::Escape("($($topic.Name)") -and $indexText -notmatch [regex]::Escape("/$($topic.Name)")) {
			$problems.Add("Файл не в индексе: $($spec[1]) -> $($topic.Name)")
		}
	}
}

# Ссылки и пути в документах
$docs = @(Get-Item -LiteralPath (Join-Path $ProjectRoot 'CLAUDE.md'))
$docs += Get-ChildItem -LiteralPath $claudeDir -Filter '*.md' -File -Recurse
foreach ($doc in $docs) {
	$relativeDoc = Relative $doc.FullName
	if ($ExcludedDocs | Where-Object { $relativeDoc -eq ".claude/$_" }) { continue }
	$raw = Read-Doc $doc.FullName
	if ($raw -match '(?<![\w./-])docs/(?:pitfalls|decisions|codestyle)\.md') { $problems.Add("Старый путь шаблона: $relativeDoc") }
	$text = [regex]::Replace((Without-Fences $raw), '(?s)^---\n.*?\n---(?:\n|$)', '')
	foreach ($link in [regex]::Matches($text, '\[[^\]\r\n]*\]\((<[^>\r\n]+>|[^)\r\n]+)\)')) {
		Test-Reference $doc.FullName $link.Groups[1].Value $false
	}
	foreach ($inline in [regex]::Matches($text, '(?<!`)`([^`\r\n]+)`(?!`)')) {
		$target = $inline.Groups[1].Value.Trim()
		if ($target -match '\s') { continue }
		if ($target -match '^(?:\.claude|tools|backup)/' -or $target -eq 'CLAUDE.md') { Test-Reference $doc.FullName $target $true }
	}
}

# Памятки хука
try {
	$reminders = (Read-Doc (Join-Path $claudeDir 'hooks/roblox-mcp-reminders.json')) | ConvertFrom-Json
	$settings = (Read-Doc (Join-Path $claudeDir 'settings.json')) | ConvertFrom-Json
	$matchers = @($settings.hooks.PreToolUse | ForEach-Object { $_.matcher })
	foreach ($tool in $reminders.PSObject.Properties.Name) {
		if (-not ($matchers | Where-Object { $tool -match $_ })) { $problems.Add("Памятка без матчера в settings.json: $tool") }
		foreach ($line in $reminders.$tool) {
			foreach ($path in [regex]::Matches($line, '\.claude/[\w./-]+\.md')) {
				if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $path.Value))) { $problems.Add("Битый путь в памятке: $tool -> $($path.Value)") }
			}
		}
	}
} catch {
	$problems.Add("Некорректный JSON памяток или settings: $($_.Exception.Message)")
}

if ($problems.Count -gt 0) {
	$problems | Sort-Object -Unique | ForEach-Object { Write-Output $_ }
	exit 1
}
Write-Output "OK: $ruleCount правил, $linkCount ссылок и путей, индексы и памятки сходятся."
Write-Output 'Смысл документации и соответствие Source в Studio проверяются отдельно.'
