[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$CodexHome = $(
        if ($env:CODEX_HOME) { $env:CODEX_HOME }
        else { Join-Path ([Environment]::GetFolderPath('UserProfile')) '.codex' }
    ),
    [string]$AgentsHome = $(Join-Path ([Environment]::GetFolderPath('UserProfile')) '.agents'),
    [switch]$SkipConfig
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$manifestPath = Join-Path $repoRoot 'portable-manifest.json'
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
$codexRoot = [IO.Path]::GetFullPath($CodexHome)
$agentsRoot = [IO.Path]::GetFullPath($AgentsHome)
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupRoot = Join-Path $codexRoot (Join-Path 'portable-backups' $timestamp)

function Assert-ManagedPath {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$AllowedRoot
    )

    $fullPath = [IO.Path]::GetFullPath($Path)
    $fullRoot = [IO.Path]::GetFullPath($AllowedRoot).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $prefix = $fullRoot + [IO.Path]::DirectorySeparatorChar
    if (-not $fullPath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to manage path outside '$fullRoot': $fullPath"
    }
}

function Backup-Target {
    param(
        [Parameter(Mandatory = $true)][string]$Target,
        [Parameter(Mandatory = $true)][string]$RelativeBackup
    )

    if (-not (Test-Path -LiteralPath $Target)) { return }
    $backupTarget = Join-Path $backupRoot $RelativeBackup
    $backupParent = Split-Path -Parent $backupTarget
    if ($PSCmdlet.ShouldProcess($Target, "Back up to $backupTarget")) {
        New-Item -ItemType Directory -Force -Path $backupParent | Out-Null
        Copy-Item -LiteralPath $Target -Destination $backupTarget -Recurse -Force
    }
}

function Install-ManagedFile {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Target,
        [Parameter(Mandatory = $true)][string]$AllowedRoot,
        [Parameter(Mandatory = $true)][string]$RelativeBackup
    )

    if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) { throw "Missing source file: $Source" }
    Assert-ManagedPath -Path $Target -AllowedRoot $AllowedRoot
    Backup-Target -Target $Target -RelativeBackup $RelativeBackup
    if ($PSCmdlet.ShouldProcess($Target, "Install from $Source")) {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Target) | Out-Null
        Copy-Item -LiteralPath $Source -Destination $Target -Force
    }
}

function Install-ManagedDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Target,
        [Parameter(Mandatory = $true)][string]$AllowedRoot,
        [Parameter(Mandatory = $true)][string]$RelativeBackup
    )

    if (-not (Test-Path -LiteralPath $Source -PathType Container)) { throw "Missing source directory: $Source" }
    Assert-ManagedPath -Path $Target -AllowedRoot $AllowedRoot
    Backup-Target -Target $Target -RelativeBackup $RelativeBackup
    if ($PSCmdlet.ShouldProcess($Target, "Replace with $Source")) {
        if (Test-Path -LiteralPath $Target) { Remove-Item -LiteralPath $Target -Recurse -Force }
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Target) | Out-Null
        Copy-Item -LiteralPath $Source -Destination $Target -Recurse -Force
    }
}

function Get-TomlAssignments {
    param([Parameter(Mandatory = $true)][string]$Path)

    $assignments = [ordered]@{}
    foreach ($line in (Get-Content -LiteralPath $Path)) {
        if ($line -match '^\s*([A-Za-z0-9_.-]+)\s*=\s*(.+?)\s*$') {
            $assignments[$Matches[1]] = "$($Matches[1]) = $($Matches[2])"
        }
    }
    return $assignments
}

function Merge-AgentConfig {
    $portableConfig = Join-Path $repoRoot 'config\agents.toml'
    $targetConfig = Join-Path $codexRoot 'config.toml'
    $desired = Get-TomlAssignments -Path $portableConfig

    if (-not (Test-Path -LiteralPath $targetConfig)) {
        Install-ManagedFile -Source $portableConfig -Target $targetConfig -AllowedRoot $codexRoot -RelativeBackup 'config.toml'
        return
    }

    Assert-ManagedPath -Path $targetConfig -AllowedRoot $codexRoot
    $inputLines = @(Get-Content -LiteralPath $targetConfig)
    $outputLines = [Collections.Generic.List[string]]::new()
    $seen = @{}
    $insideAgents = $false
    $foundAgents = $false

    foreach ($line in $inputLines) {
        if ($line -match '^\s*\[([^]]+)\]\s*$') {
            if ($insideAgents) {
                foreach ($key in $desired.Keys) {
                    if (-not $seen.ContainsKey($key)) { $outputLines.Add($desired[$key]) }
                }
            }
            $insideAgents = ($Matches[1] -eq 'agents')
            if ($insideAgents) { $foundAgents = $true }
            $outputLines.Add($line)
            continue
        }

        if ($insideAgents -and $line -match '^\s*([A-Za-z0-9_.-]+)\s*=') {
            $key = $Matches[1]
            if ($desired.Contains($key)) {
                $outputLines.Add($desired[$key])
                $seen[$key] = $true
                continue
            }
        }
        $outputLines.Add($line)
    }

    if ($insideAgents) {
        foreach ($key in $desired.Keys) {
            if (-not $seen.ContainsKey($key)) { $outputLines.Add($desired[$key]) }
        }
    }
    elseif (-not $foundAgents) {
        if ($outputLines.Count -gt 0 -and $outputLines[$outputLines.Count - 1] -ne '') { $outputLines.Add('') }
        $outputLines.Add('[agents]')
        foreach ($key in $desired.Keys) { $outputLines.Add($desired[$key]) }
    }

    Backup-Target -Target $targetConfig -RelativeBackup 'config.toml'
    if ($PSCmdlet.ShouldProcess($targetConfig, 'Merge portable [agents] settings')) {
        [IO.File]::WriteAllLines($targetConfig, $outputLines, [Text.UTF8Encoding]::new($false))
    }
}

New-Item -ItemType Directory -Force -Path $codexRoot | Out-Null
New-Item -ItemType Directory -Force -Path $agentsRoot | Out-Null

Install-ManagedFile -Source (Join-Path $repoRoot 'global\AGENTS.md') -Target (Join-Path $codexRoot 'AGENTS.md') -AllowedRoot $codexRoot -RelativeBackup 'AGENTS.md'
Install-ManagedDirectory -Source (Join-Path $repoRoot 'global\memory-bank') -Target (Join-Path $codexRoot 'memory-bank') -AllowedRoot $codexRoot -RelativeBackup 'memory-bank'

foreach ($agentFile in $manifest.agentFiles) {
    Install-ManagedFile -Source (Join-Path $repoRoot "global\agents\$agentFile") -Target (Join-Path $codexRoot "agents\$agentFile") -AllowedRoot $codexRoot -RelativeBackup "agents\$agentFile"
}

foreach ($skill in $manifest.skills) {
    Install-ManagedDirectory -Source (Join-Path $repoRoot "skills\$skill") -Target (Join-Path $agentsRoot "skills\$skill") -AllowedRoot $agentsRoot -RelativeBackup "agents-home\skills\$skill"
}

if (-not $SkipConfig) { Merge-AgentConfig }

Write-Host "Portable Codex configuration installed. Backups: $backupRoot"
Write-Host 'Restart Codex or start a new task so global instructions and skills are rediscovered.'
