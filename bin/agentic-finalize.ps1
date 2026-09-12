[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$ManifestPath,
    [switch]$AllowWrite,
    [switch]$AllowCommit
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Git([string[]]$Arguments, [string]$Root) {
    $output = & git -C $Root @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) { throw "git $($Arguments -join ' ') failed: $($output -join "`n")" }
    return @($output)
}

$manifestFull = [IO.Path]::GetFullPath($ManifestPath)
$manifest = Get-Content -Raw -LiteralPath $manifestFull | ConvertFrom-Json
if ($manifest.schemaVersion -ne 1) { throw "Unsupported finalization manifest schema: $($manifest.schemaVersion)" }
$repositoryRoot = [IO.Path]::GetFullPath([string]$manifest.repositoryRoot)
if (-not (Test-Path -LiteralPath (Join-Path $repositoryRoot '.git'))) { throw "Not a Git worktree: $repositoryRoot" }

$capture = $manifest.capture
$result = [ordered]@{ schemaVersion = 1; task = [string]$manifest.task; repositoryRoot = $repositoryRoot; capturedAt = [DateTimeOffset]::UtcNow.ToString('o') }
if ($capture.branch -eq $true) { $result.branch = ((Invoke-Git -Arguments @('branch', '--show-current') -Root $repositoryRoot) -join "`n").Trim() }
if ($capture.head -eq $true) { $result.head = ((Invoke-Git -Arguments @('rev-parse', 'HEAD') -Root $repositoryRoot) -join "`n").Trim() }
if ($capture.status -eq $true) { $result.status = @((Invoke-Git -Arguments @('status', '--short') -Root $repositoryRoot)) }
if ($capture.diffNumstat -eq $true) { $result.diffNumstat = @((Invoke-Git -Arguments @('diff', '--numstat') -Root $repositoryRoot)) }
if ($capture.showNumstat -eq $true) { $result.showNumstat = @((Invoke-Git -Arguments @('show', '--numstat', '--format=%H') -Root $repositoryRoot)) }

$roundLogProperty = $manifest.PSObject.Properties['roundLog']
if ($null -ne $roundLogProperty -and $manifest.roundLog.enabled -eq $true) {
    if (-not $AllowWrite) { throw 'Manifest requests a round-log append, but -AllowWrite was not explicitly supplied.' }
    $roundLogPath = [IO.Path]::GetFullPath((Join-Path $repositoryRoot ([string]$manifest.roundLog.path)))
    $repositoryPrefix = $repositoryRoot.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    if (-not $roundLogPath.StartsWith($repositoryPrefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'Round-log path escapes repository.' }
    if ($PSCmdlet.ShouldProcess($roundLogPath, 'Append manifest round-log record')) {
        $record = [ordered]@{}
        foreach ($property in $manifest.roundLog.record.PSObject.Properties) { $record[$property.Name] = $property.Value }
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $roundLogPath) | Out-Null
        [pscustomobject]$record | Export-Csv -LiteralPath $roundLogPath -Append -NoTypeInformation
        $result.roundLog = $roundLogPath
    }
}

$commitProperty = $manifest.PSObject.Properties['commit']
$commit = if ($null -ne $commitProperty) { $manifest.commit } else { $null }
if ($null -ne $commit -and $commit.enabled -eq $true) {
    if (-not $AllowCommit) { throw 'Manifest requests a commit, but -AllowCommit was not explicitly supplied.' }
    $paths = @($commit.paths)
    if ($paths.Count -eq 0) { throw 'Commit authorization requires an explicit non-empty paths allowlist.' }
    foreach ($relative in $paths) {
        $candidate = [IO.Path]::GetFullPath((Join-Path $repositoryRoot ([string]$relative)))
        $prefix = $repositoryRoot.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
        if (-not $candidate.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { throw "Commit path escapes repository: $relative" }
    }
    if (-not $PSCmdlet.ShouldProcess($repositoryRoot, "Stage allowlisted paths and commit '$($commit.message)'")) { return }
    [void](Invoke-Git -Arguments (@('add', '--') + $paths) -Root $repositoryRoot)
    [void](Invoke-Git -Arguments @('commit', '-m', [string]$commit.message) -Root $repositoryRoot)
    $result.postCommitHead = ((Invoke-Git -Arguments @('rev-parse', 'HEAD') -Root $repositoryRoot) -join "`n").Trim()
    $result.postCommitStatus = @((Invoke-Git -Arguments @('status', '--short') -Root $repositoryRoot))
}

$result | ConvertTo-Json -Depth 8
