[CmdletBinding()] param()
Set-StrictMode -Version Latest; $ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'));$pwsh=(Get-Process -Id $PID).Path
$script=Join-Path $repo 'bin\agentic-kernel.ps1';$fixture=Join-Path $repo 'tests\fixtures\v4-kernel-failure.json'
$result=& $pwsh -NoProfile -File $script -RequestPath $fixture | ConvertFrom-Json
if($result.status -ne 'REPLACEMENT_REQUIRED' -or $result.kernel -ne 'v4-single' -or $result.root -ne 'host-selected'){throw 'V4 kernel did not preserve single-kernel host selection.'}
if($result.replacement.role -ne 'implementer' -or $result.replacement.workerId -ne 'worker-7-replacement'){throw 'V4 failure fixture did not produce an equivalent replacement.'}
if($result.budgets.contextTokens -ne 4096 -or $result.budgets.outputTokens -ne 1024){throw 'V4 budgets were not preserved.'}
$bad=Join-Path ([IO.Path]::GetTempPath()) ('v4-kernel-bad-'+[Guid]::NewGuid().ToString('N')+'.json');Set-Content -LiteralPath $bad -Value '{"schemaVersion":1,"kind":"kernel-request","role":"x","contextSources":["..\\secret"],"budgets":{"contextTokens":1,"outputTokens":1}}'
try{$null=& $pwsh -NoProfile -File $script -RequestPath $bad 2>&1;if($LASTEXITCODE -eq 0){throw 'Invalid V4 kernel request was accepted.'}}finally{Remove-Item -LiteralPath $bad -Force -ErrorAction SilentlyContinue}
Write-Host 'V4 single-kernel and failure-replacement tests passed.'
