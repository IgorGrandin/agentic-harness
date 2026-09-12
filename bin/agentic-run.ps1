[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$FilePath,
    [string[]]$ArgumentList = @(),
    [string]$ArgumentsJson = '',
    [string]$WorkingDirectory = (Get-Location).Path,
    [ValidateRange(1, 2147483)][int]$TimeoutSeconds = 3600,
    [string]$RunId = ([Guid]::NewGuid().ToString('N')),
    [string]$Task = '',
    [string]$Phase = 'command',
    [string]$RuntimeRoot = (Join-Path ([IO.Path]::GetTempPath()) 'agentic-harness\runs'),
    [ValidateRange(0, 200)][int]$TailLines = 0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($ArgumentsJson) { $ArgumentList = @($ArgumentsJson | ConvertFrom-Json) }

function Write-JsonFile([string]$Path, $Value) {
    $json = $Value | ConvertTo-Json -Depth 8
    [IO.File]::WriteAllText($Path, $json, [Text.UTF8Encoding]::new($false))
}

function Get-BoundedTail([string]$Path, [int]$Count) {
    if ($Count -eq 0 -or -not (Test-Path -LiteralPath $Path)) { return @() }
    return @(Get-Content -LiteralPath $Path -Tail $Count | ForEach-Object {
        if ($_.Length -gt 500) { $_.Substring(0, 500) + '...' } else { $_ }
    })
}

$runtimeFull = [IO.Path]::GetFullPath($RuntimeRoot)
$workingFull = [IO.Path]::GetFullPath($WorkingDirectory)
$gitCommand = Get-Command git -ErrorAction SilentlyContinue
$gitRootText = if ($null -ne $gitCommand) { & $gitCommand.Source -C $workingFull rev-parse --show-toplevel 2>$null } else { $null }
if ($null -ne $gitCommand -and $LASTEXITCODE -eq 0 -and $gitRootText) {
    $gitRoot = [IO.Path]::GetFullPath(($gitRootText -join '').Trim()).TrimEnd('\', '/')
    $gitPrefix = $gitRoot + [IO.Path]::DirectorySeparatorChar
    if ($runtimeFull -eq $gitRoot -or $runtimeFull.StartsWith($gitPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "RuntimeRoot must be outside the Git worktree: $gitRoot"
    }
}
$runDirectory = Join-Path $runtimeFull $RunId
New-Item -ItemType Directory -Force -Path $runDirectory | Out-Null
$stdoutLog = Join-Path $runDirectory 'stdout.log'
$stderrLog = Join-Path $runDirectory 'stderr.log'
$statePath = Join-Path $runDirectory 'state.json'
$resultPath = Join-Path $runDirectory 'result.json'
$startedAt = [DateTimeOffset]::UtcNow

$state = [ordered]@{
    schemaVersion = 1; runId = $RunId; task = $Task; phase = $Phase
    status = 'running'; startedAt = $startedAt.ToString('o'); completedAt = $null
    command = [ordered]@{ filePath = $FilePath; workingDirectory = $workingFull; argumentsPersisted = $false }
    resultPath = $resultPath
}
Write-JsonFile -Path $statePath -Value $state

$process = $null
$status = 'failed'
$exitCode = $null
$errorText = $null
try {
    $process = Start-Process -FilePath $FilePath -ArgumentList $ArgumentList -WorkingDirectory $state.command.workingDirectory -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog -PassThru
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        $status = 'timeout'
        try { $process.Kill($true) } catch { $process.Kill() }
        $process.WaitForExit()
        $exitCode = $process.ExitCode
    }
    else {
        $exitCode = $process.ExitCode
        $status = if ($exitCode -eq 0) { 'completed' } else { 'failed' }
    }
}
catch {
    $errorText = $_.Exception.Message
}

$completedAt = [DateTimeOffset]::UtcNow
$durationMs = [long]($completedAt - $startedAt).TotalMilliseconds
$summaryParts = [Collections.Generic.List[string]]::new()
if ($errorText) { $summaryParts.Add($errorText) }
$stderrTail = @(Get-BoundedTail -Path $stderrLog -Count $TailLines)
$stdoutTail = @(Get-BoundedTail -Path $stdoutLog -Count $TailLines)
if ($stderrTail.Count -gt 0) { $summaryParts.Add(($stderrTail -join "`n")) }
elseif ($stdoutTail.Count -gt 0) { $summaryParts.Add(($stdoutTail -join "`n")) }

$result = [ordered]@{
    schemaVersion = 1; runId = $RunId; task = $Task; phase = $Phase; status = $status
    exitCode = $exitCode; durationMs = $durationMs
    startedAt = $startedAt.ToString('o'); completedAt = $completedAt.ToString('o')
    stdoutLog = $stdoutLog; stderrLog = $stderrLog; statePath = $statePath; resultPath = $resultPath
    summaryText = ($summaryParts -join "`n")
}
Write-JsonFile -Path $resultPath -Value $result
$state.status = $status
$state.completedAt = $completedAt.ToString('o')
$state.result = [ordered]@{ exitCode = $exitCode; durationMs = $durationMs; stdoutLog = $stdoutLog; stderrLog = $stderrLog }
Write-JsonFile -Path $statePath -Value $state
$result | ConvertTo-Json -Compress -Depth 8
if ($status -eq 'completed') { exit 0 }
if ($status -eq 'timeout') { exit 124 }
exit 1
