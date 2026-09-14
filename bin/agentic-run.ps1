[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$FilePath,
    [string[]]$ArgumentList = @(),
    [string]$ArgumentsJson = '',
    [string]$ArgumentsFile = '',
    [string]$WorkingDirectory = (Get-Location).Path,
    [ValidateRange(1, 2147483)][int]$TimeoutSeconds = 3600,
    [string]$RunId = ([Guid]::NewGuid().ToString('N')),
    [string]$Task = '',
    [string]$Phase = 'command',
    [string]$RuntimeRoot = (Join-Path ([IO.Path]::GetTempPath()) 'agentic-harness\runs'),
    [ValidateRange(0, 200)][int]$TailLines = 0,
    [ValidateRange(256, 10485760)][int]$SummaryCapChars = 4000,
    [ValidateRange(256, 10485760)][int]$SummaryCapBytes = 65536
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($ArgumentsFile -and $ArgumentsJson) { throw 'ArgumentsJson and ArgumentsFile are mutually exclusive.' }
if ($ArgumentsFile) {
    if (-not (Test-Path -LiteralPath $ArgumentsFile -PathType Leaf)) { throw "ArgumentsFile was not found: $ArgumentsFile" }
    $ArgumentList = @(ConvertFrom-Json -InputObject ([IO.File]::ReadAllText([IO.Path]::GetFullPath($ArgumentsFile))))
} elseif ($ArgumentsJson) {
    $ArgumentList = @(ConvertFrom-Json -InputObject $ArgumentsJson)
}
if ($RunId -notmatch '^[A-Za-z0-9._-]+$') { throw "RunId contains unsafe path characters: $RunId" }

function Write-JsonFile([string]$Path, $Value) {
    $json = $Value | ConvertTo-Json -Depth 12
    [IO.File]::WriteAllText($Path, $json, [Text.UTF8Encoding]::new($false))
}

function Get-BoundedText([string]$Path, [int]$CapBytes, [int]$CapChars) {
    if (-not (Test-Path -LiteralPath $Path)) { return '' }
    $bytes = [IO.File]::ReadAllBytes($Path)
    $truncated = $bytes.Length -gt $CapBytes
    if ($truncated) { $bytes = $bytes[0..($CapBytes - 1)] }
    $text = [Text.Encoding]::UTF8.GetString($bytes)
    if ($text.Length -gt $CapChars) { $text = $text.Substring(0, $CapChars); $truncated = $true }
    if ($truncated) { return $text + "`n...[summary truncated; full log is external]" }
    return $text
}

function Get-BoundedTail([string]$Path, [int]$Count) {
    if ($Count -eq 0 -or -not (Test-Path -LiteralPath $Path)) { return @() }
    return @(Get-Content -LiteralPath $Path -Tail $Count | ForEach-Object {
        if ($_.Length -gt 500) { $_.Substring(0, 500) + '...' } else { $_ }
    })
}

function Resolve-AgentExecutable([string]$Name) {
    if ([IO.Path]::IsPathRooted($Name) -or $Name.Contains([IO.Path]::DirectorySeparatorChar) -or $Name.Contains([IO.Path]::AltDirectorySeparatorChar)) { return $Name }
    $lookupName = if ($Name -in @('npm','npm.cmd')) { 'npm.cmd' } elseif ($Name -in @('npx','npx.cmd')) { 'npx.cmd' } else { $Name }
    $command = Get-Command $lookupName -ErrorAction SilentlyContinue
    if ($null -ne $command) { return $command.Source }
    if ($Name -in @('node', 'node.exe', 'npm', 'npm.cmd', 'npx', 'npx.cmd')) {
        $localAppData = [Environment]::GetFolderPath('LocalApplicationData')
        $candidates = @((Join-Path $localAppData 'fnm_multishells'), (Join-Path $localAppData 'fnm'), (Join-Path ([Environment]::GetFolderPath('UserProfile')) 'AppData\Roaming\nvm'))
        foreach ($root in $candidates) {
            if (Test-Path -LiteralPath $root) {
                $candidate = Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -ieq $Name -or $_.Name -ieq (($Name -replace '\.cmd$','') + '.exe') } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
                if ($null -ne $candidate) { return $candidate.FullName }
            }
        }
    }
    throw "Executable was not found: $Name"
}

function Stop-ProcessTree([Diagnostics.Process]$Process) {
    if ($null -eq $Process) { return }
    try {
        if (-not $Process.HasExited) {
            & taskkill.exe /PID $Process.Id /T /F 2>$null | Out-Null
            if (-not $Process.HasExited) { $Process.Kill() }
        }
    } catch { try { $Process.Kill() } catch {} }
}

if (-not ('AgenticHarness.NativeProcess' -as [type])) {
    Add-Type @'
using System;
using System.Runtime.InteropServices;

namespace AgenticHarness {
    public static class NativeProcess {
        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool GetExitCodeProcess(IntPtr processHandle, out uint exitCode);
    }
}
'@
}

function Get-ProcessExitCode([Diagnostics.Process]$Process) {
    try {
        $nativeCode = [uint32]0
        if ([AgenticHarness.NativeProcess]::GetExitCodeProcess($Process.Handle, [ref]$nativeCode)) {
            return [int]$nativeCode
        }
    } catch { }
    return [int]$Process.ExitCode
}

$runtimeFull = [IO.Path]::GetFullPath($RuntimeRoot)
$workingFull = [IO.Path]::GetFullPath($WorkingDirectory)
$gitCommand = Get-Command git -ErrorAction SilentlyContinue
$gitRootText = if ($null -ne $gitCommand) { & $gitCommand.Source -C $workingFull rev-parse --show-toplevel 2>$null } else { $null }
if ($null -ne $gitCommand -and $LASTEXITCODE -eq 0 -and $gitRootText) {
    $gitRoot = [IO.Path]::GetFullPath(($gitRootText -join '').Trim()).TrimEnd('\', '/')
    $gitPrefix = $gitRoot + [IO.Path]::DirectorySeparatorChar
    if ($runtimeFull -eq $gitRoot -or $runtimeFull.StartsWith($gitPrefix, [StringComparison]::OrdinalIgnoreCase)) { throw "RuntimeRoot must be outside the Git worktree: $gitRoot" }
}
$runDirectory = Join-Path $runtimeFull $RunId
New-Item -ItemType Directory -Force -Path $runDirectory | Out-Null
$stdoutLog = Join-Path $runDirectory 'stdout.log'
$stderrLog = Join-Path $runDirectory 'stderr.log'
$statePath = Join-Path $runDirectory 'state.json'
$resultPath = Join-Path $runDirectory 'result.json'
$startedAt = [DateTimeOffset]::UtcNow
$resolvedFilePath = Resolve-AgentExecutable $FilePath
$state = [ordered]@{ schemaVersion = 2; runId = $RunId; task = $Task; phase = $Phase; status = 'RUNNING'; startedAt = $startedAt.ToString('o'); completedAt = $null; command = [ordered]@{ filePath = $resolvedFilePath; workingDirectory = $workingFull; argumentsPersisted = $false }; resultPath = $resultPath; stdoutLog = $stdoutLog; stderrLog = $stderrLog }
Write-JsonFile -Path $statePath -Value $state

$process = $null; $status = 'FAILED'; $exitCode = $null; $errorText = $null
try {
    # Start-Process joins ArgumentList before invoking CreateProcess.  That loses
    # empty values and changes quoting on Windows. ProcessStartInfo.ArgumentList
    # serializes each argv item independently, including spaces and metacharacters.
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $resolvedFilePath
    $startInfo.WorkingDirectory = $workingFull
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($argument in @($ArgumentList)) { [void]$startInfo.ArgumentList.Add([string]$argument) }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    if (-not $process.Start()) { throw "Unable to start executable: $resolvedFilePath" }
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) { $status = 'TIMEOUT'; Stop-ProcessTree $process; $process.WaitForExit(); $process.Refresh(); $exitCode = Get-ProcessExitCode $process }
    else { $process.Refresh(); $exitCode = Get-ProcessExitCode $process; $status = if ($exitCode -eq 0) { 'COMPLETED' } else { 'FAILED' } }
    [IO.File]::WriteAllText($stdoutLog, $stdoutTask.GetAwaiter().GetResult(), [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($stderrLog, $stderrTask.GetAwaiter().GetResult(), [Text.UTF8Encoding]::new($false))
} catch { $errorText = $_.Exception.Message; $status = 'FAILED' }

$completedAt = [DateTimeOffset]::UtcNow
$durationMs = [long]($completedAt - $startedAt).TotalMilliseconds
$stdoutText = Get-BoundedText -Path $stdoutLog -CapBytes $SummaryCapBytes -CapChars $SummaryCapChars
$stderrText = Get-BoundedText -Path $stderrLog -CapBytes $SummaryCapBytes -CapChars $SummaryCapChars
$summary = if ($errorText) { $errorText } elseif ($stderrText) { $stderrText } else { $stdoutText }
if ($summary.Length -gt $SummaryCapChars) { $summary = $summary.Substring(0, $SummaryCapChars) }
$result = [ordered]@{ schemaVersion = 2; runId = $RunId; task = $Task; phase = $Phase; status = $status; exitCode = $exitCode; durationMs = $durationMs; startedAt = $startedAt.ToString('o'); completedAt = $completedAt.ToString('o'); stdoutLog = $stdoutLog; stderrLog = $stderrLog; statePath = $statePath; resultPath = $resultPath; stdoutBytes = if (Test-Path $stdoutLog) { (Get-Item $stdoutLog).Length } else { 0 }; stderrBytes = if (Test-Path $stderrLog) { (Get-Item $stderrLog).Length } else { 0 }; summaryText = $summary; tail = [ordered]@{ stdout = @(Get-BoundedTail -Path $stdoutLog -Count $TailLines); stderr = @(Get-BoundedTail -Path $stderrLog -Count $TailLines) }; warningObserved = (($stdoutText + "`n" + $stderrText) -match '(?im)\bwarning\b'); executable = $resolvedFilePath }
Write-JsonFile -Path $resultPath -Value $result
$state.status = $status; $state.completedAt = $completedAt.ToString('o'); $state.result = [ordered]@{ exitCode = $exitCode; durationMs = $durationMs; stdoutBytes = $result.stdoutBytes; stderrBytes = $result.stderrBytes; resultPath = $resultPath }
Write-JsonFile -Path $statePath -Value $state
$result | ConvertTo-Json -Compress -Depth 12
if ($status -eq 'COMPLETED') { exit 0 }
if ($status -eq 'TIMEOUT') { exit 124 }
exit 1
