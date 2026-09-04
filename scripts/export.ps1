[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$CodexHome = $(
        if ($env:CODEX_HOME) { $env:CODEX_HOME }
        else { Join-Path ([Environment]::GetFolderPath('UserProfile')) '.codex' }
    ),
    [string]$AgentsHome = $(Join-Path ([Environment]::GetFolderPath('UserProfile')) '.agents'),
    [switch]$SkipVerify
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$manifest = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'portable-manifest.json') | ConvertFrom-Json
$codexRoot = [IO.Path]::GetFullPath($CodexHome)
$agentsRoot = [IO.Path]::GetFullPath($AgentsHome)
. (Join-Path $PSScriptRoot 'adapter-tools.ps1')

function Assert-RepositoryPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    $fullPath = [IO.Path]::GetFullPath($Path)
    $prefix = $repoRoot.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    if (-not $fullPath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to write outside repository: $fullPath"
    }
}

function Export-File {
    param([string]$Source, [string]$Target)
    if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) { throw "Missing local file: $Source" }
    Assert-RepositoryPath -Path $Target
    if ($PSCmdlet.ShouldProcess($Target, "Export from $Source")) {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Target) | Out-Null
        Copy-Item -LiteralPath $Source -Destination $Target -Force
    }
}

function Export-Directory {
    param([string]$Source, [string]$Target)
    if (-not (Test-Path -LiteralPath $Source -PathType Container)) { throw "Missing local directory: $Source" }
    Assert-RepositoryPath -Path $Target
    if ($PSCmdlet.ShouldProcess($Target, "Replace from $Source")) {
        if (Test-Path -LiteralPath $Target) { Remove-Item -LiteralPath $Target -Recurse -Force }
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Target) | Out-Null
        Copy-Item -LiteralPath $Source -Destination $Target -Recurse -Force
    }
}

$codexAdapter = Get-AdapterManifest -RepositoryRoot $repoRoot -Adapter 'Codex'
$expectedAgents = Get-AdapterInstructionContent -RepositoryRoot $repoRoot -AdapterManifest $codexAdapter
$localAgentsPath = Join-Path $codexRoot 'AGENTS.md'
if (-not (Test-Path -LiteralPath $localAgentsPath -PathType Leaf)) { throw "Missing local file: $localAgentsPath" }
$localAgents = Get-Content -Raw -LiteralPath $localAgentsPath
if ($localAgents -ne $expectedAgents) {
    throw 'The installed Codex AGENTS.md differs from its Core/Profile/Adapter sources. Update the source Markdown and run materialize.ps1 instead of exporting the generated file.'
}
Export-File -Source $localAgentsPath -Target (Join-Path $repoRoot 'global\AGENTS.md')

foreach ($memoryFile in $manifest.memoryFiles) {
    Export-File -Source (Join-Path $codexRoot "memory-bank\$memoryFile") -Target (Join-Path $repoRoot "global\memory-bank\$memoryFile")
}

foreach ($agentFile in $manifest.agentFiles) {
    Export-File -Source (Join-Path $codexRoot "agents\$agentFile") -Target (Join-Path $repoRoot "global\agents\$agentFile")
}

foreach ($skill in $manifest.skills) {
    Export-Directory -Source (Join-Path $agentsRoot "skills\$skill") -Target (Join-Path $repoRoot "skills\$skill")
}

if (-not $SkipVerify -and -not $WhatIfPreference) {
    & (Join-Path $PSScriptRoot 'verify.ps1')
    if ($LASTEXITCODE -ne 0) { throw 'Verification failed after export.' }
}

Write-Host 'Allowlisted global configuration exported. Review git diff before committing.'
