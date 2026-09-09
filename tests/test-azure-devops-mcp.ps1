[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$testRoot = [IO.Path]::GetFullPath((Join-Path $repoRoot '.test-output\azure-devops-mcp'))
$prefix = $repoRoot.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
if (-not $testRoot.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { throw "Unsafe test root: $testRoot" }
if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force }

$codex = Join-Path $testRoot 'codex'
$cursor = Join-Path $testRoot 'cursor'
$gemini = Join-Path $testRoot 'gemini'
New-Item -ItemType Directory -Force -Path $codex, $cursor, (Join-Path $gemini 'config') | Out-Null
[IO.File]::WriteAllText((Join-Path $codex 'config.toml'), "model = 'preserve-me'`n", [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $cursor 'mcp.json'), '{"mcpServers":{"existing":{"command":"keep"}}}', [Text.UTF8Encoding]::new($false))

$script = Join-Path $repoRoot 'scripts\install-azure-devops-mcp.ps1'
& $script -Organization confitecDevOps -NpxCommand 'C:\portable\npx.cmd' -CodexHome $codex -CursorHome $cursor -GeminiHome $gemini -WhatIf 6>$null
if (Test-Path -LiteralPath (Join-Path $gemini 'config\mcp_config.json')) { throw '-WhatIf created Gemini MCP config.' }

& $script -Organization confitecDevOps -NpxCommand 'C:\portable\npx.cmd' -CodexHome $codex -CursorHome $cursor -GeminiHome $gemini
& $script -Organization confitecDevOps -NpxCommand 'C:\portable\npx.cmd' -CodexHome $codex -CursorHome $cursor -GeminiHome $gemini

$toml = Get-Content -Raw -LiteralPath (Join-Path $codex 'config.toml')
if (($toml | Select-String '\[mcp_servers\.azure-devops\]' -AllMatches).Matches.Count -ne 1) { throw 'Codex MCP entry is not idempotent.' }
if (-not $toml.Contains("model = 'preserve-me'")) { throw 'Codex config was not preserved.' }
$cursorConfig = Get-Content -Raw -LiteralPath (Join-Path $cursor 'mcp.json') | ConvertFrom-Json
if (-not $cursorConfig.mcpServers.existing -or -not $cursorConfig.mcpServers.'azure-devops') { throw 'Cursor MCP merge lost or missed a server.' }
$geminiConfig = Get-Content -Raw -LiteralPath (Join-Path $gemini 'config\mcp_config.json') | ConvertFrom-Json
if (-not $geminiConfig.mcpServers.'azure-devops') { throw 'Antigravity MCP entry missing.' }

Write-Host 'Azure DevOps MCP installer tests passed.'
