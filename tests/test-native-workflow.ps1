[CmdletBinding()]
param()
Set-StrictMode -Version Latest; $ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'));$fixtureSource=Join-Path $repo 'tests\fixtures\workflow-project';$root=Join-Path ([IO.Path]::GetTempPath()) ('agentic-native-'+[Guid]::NewGuid().ToString('N'));$runtime=Join-Path ([IO.Path]::GetTempPath()) ('agentic-native-runtime-'+[Guid]::NewGuid().ToString('N'));$pwsh=(Get-Process -Id $PID).Path
New-Item -ItemType Directory -Force -Path $root|Out-Null;Copy-Item -LiteralPath $fixtureSource -Destination (Join-Path $root 'project') -Recurse; $project=Join-Path $root 'project';& git -C $project init --quiet;& git -C $project config user.email tests@example.invalid;& git -C $project config user.name Tests;& git -C $project add .;& git -C $project commit --quiet -m fixture
try {
 $dispatch=Join-Path $repo 'bin\agentic-execute.ps1';$receipts=Join-Path $repo 'bin\workflow-receipts.ps1'
 $start=& $pwsh -NoProfile -File $dispatch -Action start -ProjectRoot $project -WorkflowId /execute -RunId native-test -RuntimeRoot $runtime|ConvertFrom-Json
 if($start.status -ne 'READY' -or $start.mode -ne 'NATIVE' -or @($start.nativeRoles).Count -lt 3){throw 'Native registered workflow did not return its role contract.'}
 & $pwsh -NoProfile -File $receipts -Action implementation -ProjectRoot $project -RunId native-test -RuntimeRoot $runtime|Out-Null
 & $pwsh -NoProfile -File $receipts -Action review -ProjectRoot $project -RunId native-test -RuntimeRoot $runtime -ReviewStatus APPROVED|Out-Null
 $guard=& $pwsh -NoProfile -File $receipts -Action gate-guard -ProjectRoot $project -RunId native-test -RuntimeRoot $runtime|ConvertFrom-Json;if($guard.status -ne 'ALLOWED'){throw 'Approved review did not allow gate.'}
 [IO.File]::AppendAllText((Join-Path $project 'implementation.md'),"`nchanged after review`n")
 $blocked=& $pwsh -NoProfile -File $receipts -Action gate-guard -ProjectRoot $project -RunId native-test -RuntimeRoot $runtime 2>&1;if($LASTEXITCODE -eq 0 -or ($blocked -join "`n") -notmatch 'tree changed'){throw 'Tree drift did not invalidate review.'}
 & $pwsh -NoProfile -File $receipts -Action review -ProjectRoot $project -RunId native-test -RuntimeRoot $runtime -ReviewStatus APPROVED|Out-Null
 & $pwsh -NoProfile -File $receipts -Action gate -ProjectRoot $project -RunId native-test -RuntimeRoot $runtime -GateStatus GREEN -ManifestPath (Join-Path $runtime 'manifests\native-test.json')|Out-Null
 $final=& $pwsh -NoProfile -File $receipts -Action finalization-guard -ProjectRoot $project -RunId native-test -RuntimeRoot $runtime|ConvertFrom-Json;if($final.status -ne 'ALLOWED'){throw 'Green gate did not allow finalization.'}
 $policy=Get-Content -Raw (Join-Path $repo 'config\wait-policy.json')|ConvertFrom-Json;if($policy.defaultCommandTimeoutSeconds -le 30){throw 'Default wait policy is not long.'}
} finally {Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue;Remove-Item -LiteralPath $runtime -Recurse -Force -ErrorAction SilentlyContinue}
Write-Host 'Native workflow contract, receipts, state, drift guards, and wait policy tests passed.'
