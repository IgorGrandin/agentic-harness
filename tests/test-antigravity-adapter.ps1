[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$testRoot = [IO.Path]::GetFullPath((Join-Path $repoRoot '.test-output\antigravity'))
$allowedPrefix = $repoRoot.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
if (-not $testRoot.StartsWith($allowedPrefix, [StringComparison]::OrdinalIgnoreCase)) { throw "Unsafe test root: $testRoot" }

. (Join-Path $repoRoot 'scripts\adapter-tools.ps1')
$pathEscapeRejected = $false
try { [void](Resolve-RepositoryPath -RepositoryRoot $repoRoot -RelativePath '..\outside.md') }
catch { $pathEscapeRejected = $true }
if (-not $pathEscapeRejected) { throw 'Adapter path traversal was not rejected.' }

if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force }
$geminiHome = Join-Path $testRoot 'gemini-home'
$harnessHome = Join-Path $testRoot 'harness-home'
$codexHome = Join-Path $testRoot 'codex-home'
$agentsHome = Join-Path $testRoot 'agents-home'
$sample = Join-Path $testRoot 'sample.log'
New-Item -ItemType Directory -Force -Path $testRoot | Out-Null
[IO.File]::WriteAllText($sample, 'read-only evidence sample', [Text.UTF8Encoding]::new($false))
$sampleHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sample).Hash

& (Join-Path $repoRoot 'scripts\install.ps1') -Runtime Antigravity -GeminiHome $geminiHome -CodexHome $codexHome -AgentsHome $agentsHome -HarnessHome $harnessHome -WhatIf 6>$null
if (Test-Path -LiteralPath (Join-Path $geminiHome 'GEMINI.md')) { throw 'Antigravity -WhatIf wrote GEMINI.md.' }
if (Test-Path -LiteralPath $harnessHome) { throw 'Global -WhatIf wrote the shared harness.' }
if (Test-Path -LiteralPath $codexHome) { throw 'Antigravity -WhatIf touched Codex home.' }
if (Test-Path -LiteralPath $agentsHome) { throw 'Antigravity -WhatIf touched shared agents home.' }

& (Join-Path $repoRoot 'scripts\install.ps1') -Runtime Antigravity -GeminiHome $geminiHome -CodexHome $codexHome -AgentsHome $agentsHome -HarnessHome $harnessHome
$installed = Join-Path $geminiHome 'GEMINI.md'
if (-not (Test-Path -LiteralPath $installed -PathType Leaf)) { throw 'Antigravity GEMINI.md was not installed.' }

$expectedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $repoRoot 'adapters\antigravity\GEMINI.md')).Hash
$actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $installed).Hash
if ($expectedHash -ne $actualHash) { throw 'Installed Antigravity base rules differ from the materialized adapter.' }
if (-not (Test-Path -LiteralPath (Join-Path $harnessHome 'profiles\software\PROFILE.md'))) { throw 'Shared harness was not installed.' }

$content = Get-Content -Raw -LiteralPath $installed
foreach ($marker in @('Windows 11', 'PowerShell', 'OBSERVED FACT', 'PRIVILEGED / DESTRUCTIVE', 'Inspect before modifying', 'Knowledge / Second Brain Profile', 'Home Profile', 'HUMAN REVIEW', 'STRONG CONFIRMATION')) {
    if (-not $content.Contains($marker)) { throw "Antigravity smoke contract missing: $marker" }
}

$readBack = Get-Content -Raw -LiteralPath $sample
if ($readBack -ne 'read-only evidence sample') { throw 'PowerShell read-only smoke check returned unexpected content.' }
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sample).Hash -ne $sampleHash) { throw 'Read-only smoke check modified its input.' }

if (-not (Test-Path -LiteralPath (Join-Path $codexHome 'AGENTS.md') -PathType Leaf)) { throw 'Legacy runtime selection prevented the Codex adapter from being applied.' }
if (-not (Test-Path -LiteralPath (Join-Path $agentsHome 'skills\sdd-workflow\SKILL.md') -PathType Leaf)) { throw 'Global install did not apply shared Codex-compatible skills.' }

Write-Host 'Antigravity adapter smoke tests passed.'
