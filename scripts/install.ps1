[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet('Platform', 'Codex', 'Antigravity', 'All')][string]$Runtime = 'All',
    [string]$CodexHome = $(
        if ($env:CODEX_HOME) { $env:CODEX_HOME }
        else { Join-Path ([Environment]::GetFolderPath('UserProfile')) '.codex' }
    ),
    [string]$AgentsHome = $(Join-Path ([Environment]::GetFolderPath('UserProfile')) '.agents'),
    [Alias('PlatformHome')][string]$HarnessHome = $(Join-Path ([Environment]::GetFolderPath('UserProfile')) '.agentic-harness'),
    [string]$GeminiHome = $(Join-Path ([Environment]::GetFolderPath('UserProfile')) '.gemini'),
    [ValidateSet('Knowledge', 'Home')][string[]]$AntigravityProfile = @(),
    [switch]$SkipConfig
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$manifestPath = Join-Path $repoRoot 'portable-manifest.json'
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
$codexRoot = [IO.Path]::GetFullPath($CodexHome)
$agentsRoot = [IO.Path]::GetFullPath($AgentsHome)
$harnessRoot = [IO.Path]::GetFullPath($HarnessHome)
$geminiRoot = [IO.Path]::GetFullPath($GeminiHome)
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$codexBackupRoot = Join-Path $codexRoot (Join-Path 'portable-backups' $timestamp)
$harnessBackupRoot = Join-Path $harnessRoot (Join-Path 'portable-backups' $timestamp)
$antigravityBackupRoot = Join-Path $geminiRoot (Join-Path 'portable-backups' $timestamp)
$backupRoot = $codexBackupRoot
. (Join-Path $PSScriptRoot 'adapter-tools.ps1')

if ($Runtime -ne 'All') {
    Write-Warning "-Runtime $Runtime is retained only for command compatibility. The global installer always applies every adapter."
}
if ($AntigravityProfile.Count -gt 0) {
    Write-Warning '-AntigravityProfile is retained only for command compatibility. Assistant, Knowledge, and Home are always composed.'
}

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

function Install-ManagedContent {
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$Target,
        [Parameter(Mandatory = $true)][string]$AllowedRoot,
        [Parameter(Mandatory = $true)][string]$RelativeBackup
    )

    Assert-ManagedPath -Path $Target -AllowedRoot $AllowedRoot
    Backup-Target -Target $Target -RelativeBackup $RelativeBackup
    if ($PSCmdlet.ShouldProcess($Target, 'Install materialized instructions')) {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Target) | Out-Null
        [IO.File]::WriteAllText($Target, $Content, [Text.UTF8Encoding]::new($false))
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

$backupRoot = $harnessBackupRoot
if ($PSCmdlet.ShouldProcess($harnessRoot, 'Create global agentic harness root')) { New-Item -ItemType Directory -Force -Path $harnessRoot | Out-Null }
foreach ($directory in $manifest.harnessInstall.directories) {
    Install-ManagedDirectory -Source (Join-Path $repoRoot $directory) -Target (Join-Path $harnessRoot $directory) -AllowedRoot $harnessRoot -RelativeBackup $directory
}
foreach ($file in $manifest.harnessInstall.files) {
    Install-ManagedFile -Source (Join-Path $repoRoot $file) -Target (Join-Path $harnessRoot $file) -AllowedRoot $harnessRoot -RelativeBackup $file
}
Write-Host "Global agentic harness installed. Backups: $harnessBackupRoot"

$backupRoot = $codexBackupRoot
if ($PSCmdlet.ShouldProcess($codexRoot, 'Create Codex configuration root')) { New-Item -ItemType Directory -Force -Path $codexRoot | Out-Null }
if ($PSCmdlet.ShouldProcess($agentsRoot, 'Create shared agents root')) { New-Item -ItemType Directory -Force -Path $agentsRoot | Out-Null }

Install-ManagedFile -Source (Join-Path $repoRoot 'global\AGENTS.md') -Target (Join-Path $codexRoot 'AGENTS.md') -AllowedRoot $codexRoot -RelativeBackup 'AGENTS.md'
Install-ManagedDirectory -Source (Join-Path $repoRoot 'global\memory-bank') -Target (Join-Path $codexRoot 'memory-bank') -AllowedRoot $codexRoot -RelativeBackup 'memory-bank'

foreach ($agentFile in $manifest.agentFiles) {
    Install-ManagedFile -Source (Join-Path $repoRoot "global\agents\$agentFile") -Target (Join-Path $codexRoot "agents\$agentFile") -AllowedRoot $codexRoot -RelativeBackup "agents\$agentFile"
}

foreach ($skill in $manifest.skills) {
    Install-ManagedDirectory -Source (Join-Path $repoRoot "skills\$skill") -Target (Join-Path $agentsRoot "skills\$skill") -AllowedRoot $agentsRoot -RelativeBackup "agents-home\skills\$skill"
}

if (-not $SkipConfig) { Merge-AgentConfig }
Write-Host "Portable Codex configuration installed. Backups: $codexBackupRoot"
Write-Host 'Restart Codex or start a new task so global instructions and skills are rediscovered.'

$backupRoot = $antigravityBackupRoot
$adapter = Get-AdapterManifest -RepositoryRoot $repoRoot -Adapter 'Antigravity'
$content = Get-AdapterInstructionContent -RepositoryRoot $repoRoot -AdapterManifest $adapter
if ($PSCmdlet.ShouldProcess($geminiRoot, 'Create Antigravity configuration root')) { New-Item -ItemType Directory -Force -Path $geminiRoot | Out-Null }
Install-ManagedContent -Content $content -Target (Join-Path $geminiRoot 'GEMINI.md') -AllowedRoot $geminiRoot -RelativeBackup 'GEMINI.md'
Write-Host "Portable Antigravity rules installed. Backups: $antigravityBackupRoot"
Write-Host 'Restart Antigravity so global rules are rediscovered.'
Write-Host "Ollama adapter materialized at $(Join-Path $harnessRoot 'adapters\ollama'). Runtime installation and model weights remain external."
