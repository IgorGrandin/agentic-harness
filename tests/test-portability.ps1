[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$testRoot = [IO.Path]::GetFullPath((Join-Path $repoRoot '.test-output\portability'))
$allowedPrefix = $repoRoot.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
if (-not $testRoot.StartsWith($allowedPrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Unsafe test root: $testRoot"
}

if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force }
$testCodexHome = Join-Path $testRoot 'codex-home'
$testAgentsHome = Join-Path $testRoot 'agents-home'
$testCursorHome = Join-Path $testRoot 'cursor-home'
$testHarnessHome = Join-Path $testRoot 'harness-home'
$testGeminiHome = Join-Path $testRoot 'gemini-home'
New-Item -ItemType Directory -Force -Path (Join-Path $testCodexHome 'memory-bank'), (Join-Path $testAgentsHome 'skills') | Out-Null

Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'fixtures\existing-config.toml') -Destination (Join-Path $testCodexHome 'config.toml')
[IO.File]::WriteAllText((Join-Path $testCodexHome 'AGENTS.md'), 'old global instructions', [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $testCodexHome 'memory-bank\INDEX.md'), 'old memory', [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $testCodexHome 'auth.json'), '{"must":"stay local"}', [Text.UTF8Encoding]::new($false))

$beforeWhatIf = Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $testCodexHome 'AGENTS.md')
& (Join-Path $repoRoot 'scripts\install.ps1') -CodexHome $testCodexHome -CursorHome $testCursorHome -AgentsHome $testAgentsHome -HarnessHome $testHarnessHome -GeminiHome $testGeminiHome -WhatIf 6>$null
$afterWhatIf = Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $testCodexHome 'AGENTS.md')
if ($beforeWhatIf.Hash -ne $afterWhatIf.Hash) { throw '-WhatIf mutated AGENTS.md.' }
if (Test-Path -LiteralPath $testHarnessHome) { throw '-WhatIf created the global harness home.' }
if (Test-Path -LiteralPath $testGeminiHome) { throw '-WhatIf created the Antigravity home.' }
if (Test-Path -LiteralPath $testCursorHome) { throw '-WhatIf created the Cursor home.' }

& (Join-Path $repoRoot 'scripts\install.ps1') -CodexHome $testCodexHome -CursorHome $testCursorHome -AgentsHome $testAgentsHome -HarnessHome $testHarnessHome -GeminiHome $testGeminiHome
if (-not (Test-Path -LiteralPath (Join-Path $testGeminiHome 'GEMINI.md') -PathType Leaf)) { throw 'Global install did not apply the Antigravity adapter.' }

function Assert-SameFile {
    param([string]$Expected, [string]$Actual)
    if (-not (Test-Path -LiteralPath $Actual -PathType Leaf)) { throw "Missing installed file: $Actual" }
    $expectedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $Expected).Hash
    $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $Actual).Hash
    if ($expectedHash -ne $actualHash) { throw "Installed file differs: $Actual" }
}

Assert-SameFile -Expected (Join-Path $repoRoot 'global\AGENTS.md') -Actual (Join-Path $testCodexHome 'AGENTS.md')
Assert-SameFile -Expected (Join-Path $repoRoot 'adapters\cursor\rules\agentic-harness.mdc') -Actual (Join-Path $testCursorHome 'rules\agentic-harness.mdc')
Assert-SameFile -Expected (Join-Path $repoRoot 'global\memory-bank\INDEX.md') -Actual (Join-Path $testCodexHome 'memory-bank\INDEX.md')
Assert-SameFile -Expected (Join-Path $repoRoot 'global\memory-bank\INDEX.md') -Actual (Join-Path $testCursorHome 'memory-bank\INDEX.md')
Assert-SameFile -Expected (Join-Path $repoRoot 'global\agents\scout.toml') -Actual (Join-Path $testCodexHome 'agents\scout.toml')
Assert-SameFile -Expected (Join-Path $repoRoot 'skills\sdd-workflow\SKILL.md') -Actual (Join-Path $testAgentsHome 'skills\sdd-workflow\SKILL.md')
Assert-SameFile -Expected (Join-Path $repoRoot 'core\policies\context-memory.md') -Actual (Join-Path $testHarnessHome 'core\policies\context-memory.md')
Assert-SameFile -Expected (Join-Path $repoRoot 'profiles\assistant\PROFILE.md') -Actual (Join-Path $testHarnessHome 'profiles\assistant\PROFILE.md')
Assert-SameFile -Expected (Join-Path $repoRoot 'profiles\knowledge\PROFILE.md') -Actual (Join-Path $testHarnessHome 'profiles\knowledge\PROFILE.md')
Assert-SameFile -Expected (Join-Path $repoRoot 'profiles\home\PROFILE.md') -Actual (Join-Path $testHarnessHome 'profiles\home\PROFILE.md')
Assert-SameFile -Expected (Join-Path $repoRoot 'adapters\ollama\Modelfile.qwen-local') -Actual (Join-Path $testHarnessHome 'adapters\ollama\Modelfile.qwen-local')
Assert-SameFile -Expected (Join-Path $repoRoot 'mcp\registry.json') -Actual (Join-Path $testHarnessHome 'mcp\registry.json')
Assert-SameFile -Expected (Join-Path $repoRoot 'global\memory-bank\INDEX.md') -Actual (Join-Path $testHarnessHome 'global\memory-bank\INDEX.md')

$codexInstructions = Get-Content -Raw -LiteralPath (Join-Path $testCodexHome 'AGENTS.md')
foreach ($marker in @(
    'four permanent profiles',
    'This Codex adapter activates Coder',
    'Assistant, Knowledge, and Home remain known platform profiles but are not activated',
    '`CONNECTED` through `~/.codex/memory-bank/`',
    'Sol, Luna, and Terra are `CONFIGURED`',
    'Every Codex spawn must explicitly set `model` and `reasoning_effort`',
    'Never use `fork_turns: "all"` for Luna or Terra',
    'Use a Sol subagent only for consequential judgment',
    'not an automatic Codex fallback'
)) {
    if (-not $codexInstructions.Contains($marker)) { throw "Codex platform-awareness contract missing: $marker" }
}

$antigravityRules = Get-Content -Raw -LiteralPath (Join-Path $testGeminiHome 'GEMINI.md')
foreach ($marker in @('Personal Assistant Profile', 'Knowledge / Second Brain Profile', 'Home Profile')) {
    if (-not $antigravityRules.Contains($marker)) { throw "Global Antigravity composition missing: $marker" }
}

$mergedConfig = Get-Content -Raw -LiteralPath (Join-Path $testCodexHome 'config.toml')
foreach ($requiredText in @(
    '[features]',
    'js_repl = true',
    'custom_local_key = "preserve-me"',
    'default_subagent_model = "gpt-5.6-luna"',
    'default_subagent_reasoning_effort = "medium"',
    '[mcp_servers.local_example]',
    'command = "local-only-command"'
)) {
    if (-not $mergedConfig.Contains($requiredText)) { throw "Merged config lost or missed: $requiredText" }
}

$backups = @(Get-ChildItem -LiteralPath (Join-Path $testCodexHome 'portable-backups') -Directory)
if ($backups.Count -ne 1) { throw "Expected exactly one real-install backup, found $($backups.Count)." }
if (-not (Test-Path -LiteralPath (Join-Path $backups[0].FullName 'config.toml'))) { throw 'config.toml backup missing.' }
if (-not (Test-Path -LiteralPath (Join-Path $backups[0].FullName 'AGENTS.md'))) { throw 'AGENTS.md backup missing.' }

$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
$exportRepoParent = Join-Path $tempBase ("codex-portability-test-" + [Guid]::NewGuid().ToString('N'))
$exportRepo = Join-Path $exportRepoParent 'agentic-harness'
$tempPrefix = $tempBase + [IO.Path]::DirectorySeparatorChar
if (-not ([IO.Path]::GetFullPath($exportRepoParent)).StartsWith($tempPrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Unsafe export test root: $exportRepoParent"
}

try {
    New-Item -ItemType Directory -Force -Path $exportRepoParent | Out-Null
    New-Item -ItemType Directory -Force -Path $exportRepo | Out-Null
    Get-ChildItem -LiteralPath $repoRoot -Force |
        Where-Object { $_.Name -notin @('.git', '.test-output') } |
        Copy-Item -Destination $exportRepo -Recurse -Force
    Add-Content -LiteralPath (Join-Path $testCodexHome 'memory-bank\preferences.md') -Value "`n- Export test sentinel."
    & (Join-Path $exportRepo 'scripts\export.ps1') -CodexHome $testCodexHome -AgentsHome $testAgentsHome
    $exportedPreferences = Get-Content -Raw -LiteralPath (Join-Path $exportRepo 'global\memory-bank\preferences.md')
    if (-not $exportedPreferences.Contains('Export test sentinel.')) { throw 'Allowlisted memory export did not occur.' }
    if (Test-Path -LiteralPath (Join-Path $exportRepo 'auth.json')) { throw 'Forbidden auth.json was exported.' }
}
finally {
    if (Test-Path -LiteralPath $exportRepoParent) { Remove-Item -LiteralPath $exportRepoParent -Recurse -Force }
}

& (Join-Path $repoRoot 'scripts\verify.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Final repository verification failed.' }

Write-Host 'Portability tests passed.'
