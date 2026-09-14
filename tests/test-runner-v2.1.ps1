[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$root = Join-Path ([IO.Path]::GetTempPath()) ('agentic-harness-v21-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $root | Out-Null
$runner = Join-Path $repo 'bin\agentic-run.ps1'; $pwsh = if ($null -ne (Get-Command pwsh -ErrorAction SilentlyContinue)) { (Get-Command pwsh).Source } else { (Get-Process -Id $PID).Path }
function Invoke-Test([string]$script, [int]$timeout = 10, [string[]]$extra = @()) {
    $argsFile = Join-Path $root ($script + '.args.json')
    @('-NoProfile','-File',(Join-Path $root $script)) | ConvertTo-Json -Compress | Set-Content -LiteralPath $argsFile
    $out = & $pwsh -NoProfile -File $runner -FilePath $pwsh -ArgumentsFile $argsFile -RuntimeRoot $root -TimeoutSeconds $timeout -SummaryCapChars 256 -SummaryCapBytes 256 @extra 2>$null
    [pscustomobject]@{ code = $LASTEXITCODE; result = ($out | ConvertFrom-Json) }
}
[IO.File]::WriteAllText((Join-Path $root 'success.ps1'), "Write-Output 'success'`nWrite-Warning 'known warning'`nexit 0`n")
$ok = Invoke-Test 'success.ps1'; if ($ok.code -ne 0 -or $ok.result.status -ne 'COMPLETED' -or -not $ok.result.warningObserved) { throw 'V2.1 warning-success contract failed.' }
[IO.File]::WriteAllText((Join-Path $root 'argv.ps1'), "`$args | ConvertTo-Json -Compress`n")
$argvValues = @('space value','quote"value','', 'semi; pipe| amp& dollar$ paren()', 'trailing\\')
$argvFile = Join-Path $root 'argv.args.json'
@('-NoProfile','-File',(Join-Path $root 'argv.ps1')) + $argvValues | ConvertTo-Json -Compress | Set-Content -LiteralPath $argvFile
$argvOutput = & $pwsh -NoProfile -File $runner -FilePath $pwsh -ArgumentsFile $argvFile -RuntimeRoot $root -TimeoutSeconds 10 2>$null
$argvResult = $argvOutput | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $argvResult.status -ne 'COMPLETED') { throw 'V2.1 argv sentinel did not complete.' }
$argvObserved = Get-Content -Raw -LiteralPath $argvResult.stdoutLog | ConvertFrom-Json
if ((@($argvObserved) -join "`0") -cne ($argvValues -join "`0")) { throw 'V2.1 argv sentinel lost an exact argument.' }
[IO.File]::WriteAllText((Join-Path $root 'fail.ps1'), "[Console]::Error.WriteLine('failure')`nexit 17`n")
$bad = Invoke-Test 'fail.ps1'; if ($bad.code -eq 0 -or $bad.result.status -ne 'FAILED' -or $bad.result.exitCode -ne 17) { throw 'V2.1 failure contract failed.' }
[IO.File]::WriteAllText((Join-Path $root 'timeout.ps1'), "Start-Sleep -Seconds 5`n")
$slow = Invoke-Test 'timeout.ps1' 1; if ($slow.code -ne 124 -or $slow.result.status -ne 'TIMEOUT') { throw 'V2.1 timeout contract failed.' }
[IO.File]::WriteAllText((Join-Path $root 'large.ps1'), "1..1000 | ForEach-Object { Write-Output ('x' * 100) }`n")
$large = Invoke-Test 'large.ps1' 10 @('-TailLines','2'); if ($large.result.status -ne 'COMPLETED' -or $large.result.summaryText.Length -gt 256 -or $large.result.stdoutBytes -le 256) { throw 'V2.1 bounded output contract failed.' }
foreach ($name in @('node','npm','npx')) {
    if ($null -eq (Get-Command ($(if ($name -eq 'node') { 'node' } else { "$name.cmd" })) -ErrorAction SilentlyContinue)) { continue }
    $probeArgs = Join-Path $root ($name + '-args.json')
    @('--version') | ConvertTo-Json -Compress | Set-Content -LiteralPath $probeArgs
    $probe = & $pwsh -NoProfile -File $runner -FilePath $name -ArgumentsFile $probeArgs -RuntimeRoot $root 2>$null
    if ($LASTEXITCODE -ne 0 -or (($probe | ConvertFrom-Json).status -ne 'COMPLETED')) { throw "Resolver probe failed: $name" }
}
if (-not (Test-Path -LiteralPath $ok.result.stdoutLog) -or -not (Test-Path -LiteralPath $ok.result.statePath)) { throw 'External log/state refs missing.' }
Remove-Item -LiteralPath $root -Recurse -Force
Write-Host 'V2.1 runner tests passed.'
