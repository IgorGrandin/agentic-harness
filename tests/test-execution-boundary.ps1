[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$testRoot = [IO.Path]::GetFullPath((Join-Path $repoRoot '.test-output\execution-boundary'))
$allowedPrefix = $repoRoot.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
if (-not $testRoot.StartsWith($allowedPrefix, [StringComparison]::OrdinalIgnoreCase)) { throw "Unsafe test root: $testRoot" }
if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force }
New-Item -ItemType Directory -Force -Path $testRoot | Out-Null
$runtimeTestRoot = Join-Path ([IO.Path]::GetTempPath()) ('agentic-harness-test-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $runtimeTestRoot | Out-Null

$pwsh = (Get-Process -Id $PID).Path
$runner = Join-Path $repoRoot 'bin\agentic-run.ps1'
$finalizer = Join-Path $repoRoot 'bin\agentic-finalize.ps1'

function Invoke-Runner([string[]]$RunnerArguments, [string]$OutputPath) {
    $raw = & $pwsh -NoProfile -File $runner @RunnerArguments 2> ($OutputPath + '.err')
    $runnerExitCode = $LASTEXITCODE
    [IO.File]::WriteAllText($OutputPath, ($raw -join "`n"), [Text.UTF8Encoding]::new($false))
    $json = Get-Content -Raw -LiteralPath $OutputPath | ConvertFrom-Json
    return [pscustomobject]@{ ExitCode = $runnerExitCode; Result = $json }
}

$successScript = Join-Path $testRoot 'success.ps1'
[IO.File]::WriteAllText($successScript, "Write-Output 'success-sentinel'`n", [Text.UTF8Encoding]::new($false))
$successArgs = @('-NoProfile', '-File', $successScript) | ConvertTo-Json -Compress
$success = Invoke-Runner -RunnerArguments @('-FilePath', $pwsh, '-ArgumentsJson', $successArgs, '-RuntimeRoot', $runtimeTestRoot, '-Task', 'runner-success', '-Phase', 'gate') -OutputPath (Join-Path $testRoot 'success-result.json')
if ($success.ExitCode -ne 0 -or $success.Result.status -ne 'completed' -or $success.Result.exitCode -ne 0) { throw 'Runner success contract failed.' }
if (-not (Test-Path -LiteralPath $success.Result.stdoutLog) -or (Get-Content -Raw -LiteralPath $success.Result.stdoutLog) -notmatch 'success-sentinel') { throw 'Runner did not externalize stdout.' }
$successState = Get-Content -Raw -LiteralPath $success.Result.statePath | ConvertFrom-Json
if ($successState.status -ne 'completed' -or $successState.phase -ne 'gate' -or $successState.task -ne 'runner-success') { throw 'Structured run state is invalid.' }

$failureScript = Join-Path $testRoot 'failure.ps1'
[IO.File]::WriteAllText($failureScript, "[Console]::Error.WriteLine('failure-sentinel')`nexit 7`n", [Text.UTF8Encoding]::new($false))
$failureArgs = @('-NoProfile', '-File', $failureScript) | ConvertTo-Json -Compress
$failure = Invoke-Runner -RunnerArguments @('-FilePath', $pwsh, '-ArgumentsJson', $failureArgs, '-RuntimeRoot', $runtimeTestRoot, '-TailLines', '5') -OutputPath (Join-Path $testRoot 'failure-result.json')
if ($failure.ExitCode -eq 0 -or $failure.Result.status -ne 'failed' -or $failure.Result.exitCode -ne 7) { throw 'Runner failure contract failed.' }
if ($failure.Result.summaryText -notmatch 'failure-sentinel') { throw 'Runner bounded failure summary is missing.' }

$timeoutScript = Join-Path $testRoot 'timeout.ps1'
[IO.File]::WriteAllText($timeoutScript, "Start-Sleep -Seconds 5`n", [Text.UTF8Encoding]::new($false))
$timeoutArgs = @('-NoProfile', '-File', $timeoutScript) | ConvertTo-Json -Compress
$timeout = Invoke-Runner -RunnerArguments @('-FilePath', $pwsh, '-ArgumentsJson', $timeoutArgs, '-RuntimeRoot', $runtimeTestRoot, '-TimeoutSeconds', '1') -OutputPath (Join-Path $testRoot 'timeout-result.json')
if ($timeout.ExitCode -ne 124 -or $timeout.Result.status -ne 'timeout') { throw 'Runner timeout contract failed.' }

$gitRoot = Join-Path $testRoot 'repo'
New-Item -ItemType Directory -Force -Path $gitRoot | Out-Null
& git -C $gitRoot init --quiet
[IO.File]::WriteAllText((Join-Path $gitRoot 'tracked.txt'), 'one', [Text.UTF8Encoding]::new($false))
& git -C $gitRoot add -- tracked.txt
& git -C $gitRoot -c user.name=Test -c user.email=test@example.invalid commit --quiet -m initial
[IO.File]::AppendAllText((Join-Path $gitRoot 'tracked.txt'), 'two', [Text.UTF8Encoding]::new($false))
$manifestPath = Join-Path $testRoot 'finalize.json'
$manifest = [ordered]@{
    schemaVersion = 1; task = 'finalizer-capture'; repositoryRoot = $gitRoot
    capture = [ordered]@{ branch = $true; head = $true; status = $true; diffNumstat = $true; showNumstat = $true }
    commit = [ordered]@{ enabled = $false; paths = @(); message = '' }
    roundLog = [ordered]@{ enabled = $false; path = ''; record = [ordered]@{} }
}
[IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 6), [Text.UTF8Encoding]::new($false))
$finalized = & $pwsh -NoProfile -File $finalizer -ManifestPath $manifestPath | ConvertFrom-Json
if (-not $finalized.head -or $finalized.status.Count -eq 0 -or $finalized.diffNumstat.Count -eq 0) { throw 'Finalizer capture contract failed.' }

$manifest.commit.enabled = $true
$manifest.commit.paths = @('tracked.txt')
$manifest.commit.message = 'test commit'
[IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 6), [Text.UTF8Encoding]::new($false))
$denied = Start-Process -FilePath $pwsh -ArgumentList @('-NoProfile', '-File', $finalizer, '-ManifestPath', $manifestPath) -RedirectStandardOutput (Join-Path $testRoot 'denied.out') -RedirectStandardError (Join-Path $testRoot 'denied.err') -Wait -PassThru
if ($denied.ExitCode -eq 0) { throw 'Finalizer committed without explicit -AllowCommit.' }
if ((& git -C $gitRoot status --short) -notmatch 'tracked.txt') { throw 'Denied finalization unexpectedly changed repository state.' }

Remove-Item -LiteralPath $runtimeTestRoot -Recurse -Force
Write-Host 'Deterministic execution boundary tests passed.'
