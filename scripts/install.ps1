[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet('Platform', 'Codex', 'Cursor', 'Antigravity', 'All')][string]$Runtime = 'All',
    [string]$CodexHome = $(
        if ($env:CODEX_HOME) { $env:CODEX_HOME }
        else { Join-Path ([Environment]::GetFolderPath('UserProfile')) '.codex' }
    ),
    [string]$AgentsHome = $(Join-Path ([Environment]::GetFolderPath('UserProfile')) '.agents'),
    [string]$CursorHome = $(Join-Path ([Environment]::GetFolderPath('UserProfile')) '.cursor'),
    [Alias('PlatformHome')][string]$HarnessHome = $(Join-Path ([Environment]::GetFolderPath('UserProfile')) '.agentic-harness'),
    [string]$BootstrapPython = '',
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
$cursorRoot = [IO.Path]::GetFullPath($CursorHome)
$harnessRoot = [IO.Path]::GetFullPath($HarnessHome)
$geminiRoot = [IO.Path]::GetFullPath($GeminiHome)
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$codexBackupRoot = Join-Path $codexRoot (Join-Path 'portable-backups' $timestamp)
$cursorBackupRoot = Join-Path $cursorRoot (Join-Path 'portable-backups' $timestamp)
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

function Install-ManagedLangGraphRuntime {
    param([Parameter(Mandatory = $true)][string]$ManagedRuntimeRoot)

    # A dry run must remain dependency-free: the managed runtime has not been
    # copied yet and no bootstrap interpreter should be required.
    if ($WhatIfPreference) { Write-Verbose "Would create and populate managed LangGraph runtime at $ManagedRuntimeRoot"; return }
    $lockFile = Join-Path $ManagedRuntimeRoot 'requirements-langgraph.lock'
    $venvRoot = Join-Path $ManagedRuntimeRoot 'python'
    if (-not (Test-Path -LiteralPath $lockFile -PathType Leaf)) { throw "Missing managed LangGraph lock file: $lockFile" }
    if ((Get-Content -Raw -LiteralPath $lockFile) -notmatch '(?m)--hash=sha256:') { throw "Managed LangGraph lock is not transitively hash-locked. Generate it in a networked installation phase: pwsh -File runtime\generate-langgraph-lock.ps1 -BootstrapPython <python>." }
    $bootstrap = if ($BootstrapPython) { Get-Item -LiteralPath $BootstrapPython -ErrorAction Stop } else { Get-Command python -ErrorAction SilentlyContinue }
    if ($null -eq $bootstrap) { throw 'Python is required to create the managed LangGraph runtime; pass -BootstrapPython with an existing Python 3.11+ executable or install one and rerun install.' }
    $bootstrapPath = if ($bootstrap.PSObject.Properties['Source']) { $bootstrap.Source } else { $bootstrap.FullName }
    & $bootstrapPath -c "import sys; assert sys.version_info >= (3, 11), sys.version"
    if ($LASTEXITCODE -ne 0) { throw 'BootstrapPython must be Python 3.11 or newer.' }
    $staging = "$venvRoot.staging-$([Guid]::NewGuid().ToString('N'))"
    $backup = "$venvRoot.rollback-$([Guid]::NewGuid().ToString('N'))"
    $stagingPython = Join-Path $staging 'Scripts\python.exe'
    if (-not $PSCmdlet.ShouldProcess($venvRoot, 'Atomically stage and install managed LangGraph runtime')) { return }
    try {
        & $bootstrapPath -m venv $staging
        if ($LASTEXITCODE -ne 0) { throw 'Managed Python staging virtual environment creation failed.' }
        & $stagingPython -m pip install --disable-pip-version-check --only-binary=:all: --no-cache-dir --progress-bar off --require-hashes --requirement $lockFile
        if ($LASTEXITCODE -ne 0) { throw 'Locked LangGraph runtime installation failed.' }
        & $stagingPython -c "import importlib.metadata as m; import langgraph, langgraph.checkpoint.sqlite; assert m.version('langgraph') == '1.2.11'; assert m.version('langgraph-checkpoint-sqlite') == '3.1.1'"
        if ($LASTEXITCODE -ne 0) { throw 'Managed LangGraph runtime import/version verification failed.' }
        if (Test-Path -LiteralPath $venvRoot) { Move-Item -LiteralPath $venvRoot -Destination $backup -ErrorAction Stop }
        try { Move-Item -LiteralPath $staging -Destination $venvRoot -ErrorAction Stop }
        catch { if (Test-Path -LiteralPath $backup) { Move-Item -LiteralPath $backup -Destination $venvRoot -ErrorAction SilentlyContinue }; throw }
        if (Test-Path -LiteralPath $backup) { Remove-Item -LiteralPath $backup -Recurse -Force }
    } catch {
        if (Test-Path -LiteralPath $staging) { Remove-Item -LiteralPath $staging -Recurse -Force }
        if (-not (Test-Path -LiteralPath $venvRoot) -and (Test-Path -LiteralPath $backup)) { Move-Item -LiteralPath $backup -Destination $venvRoot -ErrorAction SilentlyContinue }
        throw
    }
}

function Install-ManagedRuntimeSource {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Target,
        [Parameter(Mandatory = $true)][string]$AllowedRoot
    )

    # The managed venv is a runtime artifact, not portable source. Replacing
    # `runtime/` wholesale would delete the previous verified venv before the
    # staged replacement can be installed and rolled back.
    Assert-ManagedPath -Path $Target -AllowedRoot $AllowedRoot
    if ($PSCmdlet.ShouldProcess($Target, "Refresh portable runtime source while preserving python")) {
        New-Item -ItemType Directory -Force -Path $Target | Out-Null
        foreach ($item in Get-ChildItem -LiteralPath $Source -Force) {
            if ($item.Name -eq 'python') { continue }
            Copy-Item -LiteralPath $item.FullName -Destination (Join-Path $Target $item.Name) -Recurse -Force
        }
    }
}

function Remove-ObsoleteArchitectRole {
    param([Parameter(Mandatory = $true)][string]$CodexRoot)

    $canonical = Join-Path $CodexRoot 'agents\architect-escalation.toml'
    $obsolete = Join-Path $CodexRoot 'agents\architect_escalation.toml'
    if (-not (Test-Path -LiteralPath $obsolete -PathType Leaf)) { return }
    if (-not (Test-Path -LiteralPath $canonical -PathType Leaf)) { throw 'Cannot verify obsolete architect role ownership before canonical role is installed.' }
    $canonicalHash = (Get-FileHash -LiteralPath $canonical -Algorithm SHA256).Hash
    $obsoleteHash = (Get-FileHash -LiteralPath $obsolete -Algorithm SHA256).Hash
    if ($canonicalHash -ne $obsoleteHash) {
        Write-Warning "Preserving architect_escalation.toml because it is not an exact obsolete managed duplicate: $obsolete"
        return
    }
    if ($PSCmdlet.ShouldProcess($obsolete, 'Remove exact duplicate of canonical architect-escalation role')) { Remove-Item -LiteralPath $obsolete -Force }
}

$backupRoot = $harnessBackupRoot
if ($PSCmdlet.ShouldProcess($harnessRoot, 'Create global agentic harness root')) { New-Item -ItemType Directory -Force -Path $harnessRoot | Out-Null }
foreach ($directory in $manifest.harnessInstall.directories) {
    if ($directory -eq 'runtime') {
        Install-ManagedRuntimeSource -Source (Join-Path $repoRoot $directory) -Target (Join-Path $harnessRoot $directory) -AllowedRoot $harnessRoot
    } else {
        Install-ManagedDirectory -Source (Join-Path $repoRoot $directory) -Target (Join-Path $harnessRoot $directory) -AllowedRoot $harnessRoot -RelativeBackup $directory
    }
}
foreach ($file in $manifest.harnessInstall.files) {
    Install-ManagedFile -Source (Join-Path $repoRoot $file) -Target (Join-Path $harnessRoot $file) -AllowedRoot $harnessRoot -RelativeBackup $file
}
Install-ManagedLangGraphRuntime -ManagedRuntimeRoot (Join-Path $harnessRoot 'runtime')
Write-Host "Global agentic harness installed. Backups: $harnessBackupRoot"

$backupRoot = $codexBackupRoot
if ($PSCmdlet.ShouldProcess($codexRoot, 'Create Codex configuration root')) { New-Item -ItemType Directory -Force -Path $codexRoot | Out-Null }
if ($PSCmdlet.ShouldProcess($agentsRoot, 'Create shared agents root')) { New-Item -ItemType Directory -Force -Path $agentsRoot | Out-Null }

Install-ManagedFile -Source (Join-Path $repoRoot 'global\AGENTS.md') -Target (Join-Path $codexRoot 'AGENTS.md') -AllowedRoot $codexRoot -RelativeBackup 'AGENTS.md'
Install-ManagedDirectory -Source (Join-Path $repoRoot 'global\memory-bank') -Target (Join-Path $codexRoot 'memory-bank') -AllowedRoot $codexRoot -RelativeBackup 'memory-bank'

foreach ($agentFile in $manifest.agentFiles) {
    Install-ManagedFile -Source (Join-Path $repoRoot "global\agents\$agentFile") -Target (Join-Path $codexRoot "agents\$agentFile") -AllowedRoot $codexRoot -RelativeBackup "agents\$agentFile"
}
Remove-ObsoleteArchitectRole -CodexRoot $codexRoot

foreach ($skill in $manifest.skills) {
    Install-ManagedDirectory -Source (Join-Path $repoRoot "skills\$skill") -Target (Join-Path $agentsRoot "skills\$skill") -AllowedRoot $agentsRoot -RelativeBackup "agents-home\skills\$skill"
}

if (-not $SkipConfig) { Merge-AgentConfig }
Write-Host "Portable Codex configuration installed. Backups: $codexBackupRoot"
Write-Host 'Restart Codex or start a new task so global instructions and skills are rediscovered.'

$backupRoot = $cursorBackupRoot
$cursorAdapter = Get-AdapterManifest -RepositoryRoot $repoRoot -Adapter 'Cursor'
$cursorContent = Get-AdapterInstructionContent -RepositoryRoot $repoRoot -AdapterManifest $cursorAdapter
if ($PSCmdlet.ShouldProcess($cursorRoot, 'Create Cursor configuration root')) { New-Item -ItemType Directory -Force -Path $cursorRoot | Out-Null }
Install-ManagedContent -Content $cursorContent -Target (Join-Path $cursorRoot 'rules\agentic-harness.mdc') -AllowedRoot $cursorRoot -RelativeBackup 'rules\agentic-harness.mdc'
Install-ManagedDirectory -Source (Join-Path $repoRoot 'global\memory-bank') -Target (Join-Path $cursorRoot 'memory-bank') -AllowedRoot $cursorRoot -RelativeBackup 'memory-bank'
foreach ($agentFile in $manifest.agentFiles) {
    $source = Join-Path $repoRoot "global\agents\$agentFile"
    $raw = Get-Content -Raw -LiteralPath $source
    $name = [regex]::Match($raw, '(?m)^name\s*=\s*"([^"]+)"').Groups[1].Value
    $description = [regex]::Match($raw, '(?m)^description\s*=\s*"([^"]+)"').Groups[1].Value
    $instructions = [regex]::Match($raw, '(?s)developer_instructions\s*=\s*"""\s*(.*?)\s*"""').Groups[1].Value.Trim()
    if (-not $name -or -not $description -or -not $instructions) { throw "Cannot project Cursor agent from $source" }
    $cursorAgent = "---`nname: $name`ndescription: $description`n---`n`n$instructions`n"
    Install-ManagedContent -Content $cursorAgent -Target (Join-Path $cursorRoot "agents\$name.md") -AllowedRoot $cursorRoot -RelativeBackup "agents\$name.md"
}
Write-Host "Portable Cursor configuration installed. Backups: $cursorBackupRoot"
Write-Host 'Restart Cursor so global rules, agents, memory, and shared skills are rediscovered.'

$backupRoot = $antigravityBackupRoot
$adapter = Get-AdapterManifest -RepositoryRoot $repoRoot -Adapter 'Antigravity'
$content = Get-AdapterInstructionContent -RepositoryRoot $repoRoot -AdapterManifest $adapter
if ($PSCmdlet.ShouldProcess($geminiRoot, 'Create Antigravity configuration root')) { New-Item -ItemType Directory -Force -Path $geminiRoot | Out-Null }
Install-ManagedContent -Content $content -Target (Join-Path $geminiRoot 'GEMINI.md') -AllowedRoot $geminiRoot -RelativeBackup 'GEMINI.md'
Write-Host "Portable Antigravity rules installed. Backups: $antigravityBackupRoot"
foreach ($skill in $manifest.skills) {
    Install-ManagedDirectory -Source (Join-Path $repoRoot "skills\$skill") -Target (Join-Path $geminiRoot "config\skills\$skill") -AllowedRoot $geminiRoot -RelativeBackup "config\skills\$skill"
}
Write-Host 'Restart Antigravity so global rules are rediscovered.'
Write-Host "Ollama adapter materialized at $(Join-Path $harnessRoot 'adapters\ollama'). Runtime installation and model weights remain external."
