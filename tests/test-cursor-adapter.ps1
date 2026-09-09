[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$testRoot = [IO.Path]::GetFullPath((Join-Path $repoRoot '.test-output\cursor'))
$allowedPrefix = $repoRoot.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
if (-not $testRoot.StartsWith($allowedPrefix, [StringComparison]::OrdinalIgnoreCase)) { throw "Unsafe test root: $testRoot" }
if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force }

$cursorHome = Join-Path $testRoot 'cursor-home'
$codexHome = Join-Path $testRoot 'codex-home'
$agentsHome = Join-Path $testRoot 'agents-home'
$harnessHome = Join-Path $testRoot 'harness-home'
$geminiHome = Join-Path $testRoot 'gemini-home'

& (Join-Path $repoRoot 'scripts\install.ps1') -CursorHome $cursorHome -CodexHome $codexHome -AgentsHome $agentsHome -HarnessHome $harnessHome -GeminiHome $geminiHome -WhatIf 6>$null
if (Test-Path -LiteralPath $cursorHome) { throw 'Cursor -WhatIf created its home.' }

& (Join-Path $repoRoot 'scripts\install.ps1') -CursorHome $cursorHome -CodexHome $codexHome -AgentsHome $agentsHome -HarnessHome $harnessHome -GeminiHome $geminiHome
$rule = Join-Path $cursorHome 'rules\agentic-harness.mdc'
if (-not (Test-Path -LiteralPath $rule -PathType Leaf)) { throw 'Cursor rule was not installed.' }
$content = Get-Content -Raw -LiteralPath $rule
foreach ($marker in @('alwaysApply: true', 'Coder Profile', 'This Cursor adapter activates Coder', 'Do not infer a model')) {
    if (-not $content.Contains($marker)) { throw "Cursor rule contract missing: $marker" }
}
if (-not (Test-Path -LiteralPath (Join-Path $cursorHome 'memory-bank\INDEX.md'))) { throw 'Cursor memory projection missing.' }
foreach ($name in @('scout', 'implementer', 'verifier', 'reviewer', 'architect_escalation')) {
    $path = Join-Path $cursorHome "agents\$name.md"
    if (-not (Test-Path -LiteralPath $path)) { throw "Cursor agent projection missing: $name" }
    $agent = Get-Content -Raw -LiteralPath $path
    if ($agent -notmatch '(?s)^---\s+name:\s+' -or $agent -notmatch '(?m)^description:\s+') { throw "Invalid Cursor agent: $name" }
}
if (-not (Test-Path -LiteralPath (Join-Path $agentsHome 'skills\sdd-workflow\SKILL.md'))) { throw 'Shared Cursor/Codex skill missing.' }

& (Join-Path $repoRoot 'scripts\install.ps1') -CursorHome $cursorHome -CodexHome $codexHome -AgentsHome $agentsHome -HarnessHome $harnessHome -GeminiHome $geminiHome
if (-not (Test-Path -LiteralPath $rule)) { throw 'Second install changed final Cursor state.' }

Write-Host 'Cursor adapter smoke tests passed.'
