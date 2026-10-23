# From the project root: powershell -NoProfile -ExecutionPolicy Bypass -File tools/documentation/check-agent-docs.ps1
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

# Rules without paths load in every session; a third one needs a decision in decisions/agent-docs.md.
$UnconditionalRules = @('workflow.md', 'code-style.md')
# Client sources (briefs): never edited and not link checked. Example: @('docs/brief.md')
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
	if ($target -match '[*?{}]' -or $target -match '<[^>]+>|\.\.\.|\u2026') { return }
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
		$script:problems.Add("Broken link: $(Relative $docPath) -> $target")
		return
	}
	if ($anchor -and (Test-Path -LiteralPath $resolved -PathType Leaf) -and [System.IO.Path]::GetExtension($resolved) -eq '.md') {
		if (-not (Get-Anchors (Read-Doc $resolved)).Contains($anchor)) {
			$script:problems.Add("Missing anchor: $(Relative $docPath) -> $target")
		}
	}
}

# Required files
$required = @(
	'CLAUDE.md', '.claude/README.md', '.claude/decisions.md', '.claude/pitfalls/README.md',
	'.claude/docs/systems/README.md', '.claude/docs/concept.md', '.claude/docs/debts.md',
	'.claude/docs/roadmap-to-prototype.md', '.claude/docs/milestones-done.md',
	'.claude/docs/animation-principles.md', '.claude/docs/ui-principles.md',
	'.claude/hooks/roblox-mcp-reminders.json', '.claude/hooks/roblox-mcp-reminder.py',
	'.claude/hooks/principles-reminders.json', '.claude/hooks/principles-reminder.py', '.claude/settings.json'
)
foreach ($file in $required) {
	if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $file) -PathType Leaf)) { $problems.Add("Missing file: $file") }
}

# Rules: index in CLAUDE.md and paths
$rootText = Read-Doc (Join-Path $ProjectRoot 'CLAUDE.md')
foreach ($rule in (Get-ChildItem -LiteralPath (Join-Path $claudeDir 'rules') -Filter '*.md' -File -Recurse)) {
	$ruleCount++
	$relativeRule = $rule.FullName.Substring($claudeDir.Length + 1).Replace('\', '/')
	if ($rootText -notmatch [regex]::Escape(".claude/$relativeRule")) { $problems.Add("Rule missing from the CLAUDE.md table: $relativeRule") }
	$header = [regex]::Match((Read-Doc $rule.FullName), '(?s)^---\n(.*?)\n---(?:\n|$)')
	$pathsLine = if ($header.Success) { [regex]::Match($header.Groups[1].Value, '(?m)^paths:\s*(\[.*\])\s*$') } else { $null }
	if ($rule.Name -in $UnconditionalRules) {
		if ($header.Success) { $problems.Add("An unconditional rule must not have frontmatter: $relativeRule") }
		continue
	}
	if (-not $pathsLine -or -not $pathsLine.Success) {
		$problems.Add("Rule without paths (a third unconditional rule needs a decision): $relativeRule")
		continue
	}
	$globs = [regex]::Matches($pathsLine.Groups[1].Value, '"([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
	if (-not $globs) { $problems.Add("Empty paths: $relativeRule") }
	foreach ($glob in $globs) {
		$literal = ($glob -split '[*?]', 2)[0]
		if ($literal -and -not (Test-Path -LiteralPath (Join-Path $ProjectRoot $literal))) {
			$problems.Add("paths points to nothing: $relativeRule -> $glob")
		}
	}
}

# Section indexes
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
			$problems.Add("File missing from index: $($spec[1]) -> $($topic.Name)")
		}
	}
}

# Links and paths in documents
$docs = @(Get-Item -LiteralPath (Join-Path $ProjectRoot 'CLAUDE.md'))
$docs += Get-ChildItem -LiteralPath $claudeDir -Filter '*.md' -File -Recurse
foreach ($doc in $docs) {
	$relativeDoc = Relative $doc.FullName
	if ($ExcludedDocs | Where-Object { $relativeDoc -eq ".claude/$_" }) { continue }
	$raw = Read-Doc $doc.FullName
	if ($raw -match '(?<![\w./-])docs/(?:pitfalls|decisions|codestyle)\.md') { $problems.Add("Old template path: $relativeDoc") }
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

# Project text is English
$textFiles = @(Get-Item -LiteralPath (Join-Path $ProjectRoot 'CLAUDE.md'), (Join-Path $ProjectRoot 'README.md'))
$textFiles += Get-ChildItem -LiteralPath $claudeDir -File -Recurse | Where-Object { $_.Extension -in @('.md', '.json', '.py') }
$textFiles += Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'tools') -File -Recurse | Where-Object { $_.Extension -in @('.ps1', '.py') }
foreach ($file in $textFiles) {
	$relativeFile = Relative $file.FullName
	if ($ExcludedDocs | Where-Object { $relativeFile -eq ".claude/$_" }) { continue }
	if ((Read-Doc $file.FullName) -match '[\u0400-\u04FF]') { $problems.Add("Cyrillic text: $relativeFile") }
}

# Hook reminders
try {
	$settings = (Read-Doc (Join-Path $claudeDir 'settings.json')) | ConvertFrom-Json
	$matchers = @($settings.hooks.PreToolUse | ForEach-Object { $_.matcher })
	$reminders = (Read-Doc (Join-Path $claudeDir 'hooks/roblox-mcp-reminders.json')) | ConvertFrom-Json
	foreach ($tool in $reminders.PSObject.Properties.Name) {
		if (-not ($matchers | Where-Object { $tool -match $_ })) { $problems.Add("Reminder without a matcher in settings.json: $tool") }
		foreach ($line in $reminders.$tool) {
			foreach ($path in [regex]::Matches($line, '\.claude/[\w./-]+\.md')) {
				if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $path.Value))) { $problems.Add("Broken path in a reminder: $tool -> $($path.Value)") }
			}
		}
	}
	$principles = (Read-Doc (Join-Path $claudeDir 'hooks/principles-reminders.json')) | ConvertFrom-Json
	foreach ($group in $principles.PSObject.Properties.Name) {
		if (-not $principles.$group.keywords) { $problems.Add("Principles group without keywords: $group") }
		foreach ($line in $principles.$group.lines) {
			foreach ($path in [regex]::Matches($line, '\.claude/[\w./-]+\.md')) {
				if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $path.Value))) { $problems.Add("Broken path in principles: $group -> $($path.Value)") }
			}
		}
	}
} catch {
	$problems.Add("Invalid reminders or settings JSON: $($_.Exception.Message)")
}

if ($problems.Count -gt 0) {
	$problems | Sort-Object -Unique | ForEach-Object { Write-Output $_ }
	exit 1
}
Write-Output "OK: $ruleCount rules, $linkCount links and paths, indexes, reminders and language agree."
Write-Output 'Documentation meaning and agreement with Source in Studio are checked separately.'
