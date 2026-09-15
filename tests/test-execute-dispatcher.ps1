[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$fixture = Join-Path $repo 'tests\fixtures\workflow-project'
$dispatch = Join-Path $repo 'bin\agentic-execute.ps1'
$pwsh = (Get-Process -Id $PID).Path
$runtime = Join-Path ([IO.Path]::GetTempPath()) ('agentic-harness-dispatch-' + [Guid]::NewGuid().ToString('N'))
try {
    $registered = & $pwsh -NoProfile -File $dispatch -Action resolve -ProjectRoot $fixture -WorkflowId source-command-execute -RunId registered-resolve -RuntimeRoot $runtime | ConvertFrom-Json
    if ($registered.status -ne 'RESOLVED' -or $registered.mode -ne 'NATIVE' -or $registered.registered -ne $true) { throw 'Registered workflow resolution contract failed.' }
    $graph = & $pwsh -NoProfile -File $dispatch -Action resolve -ProjectRoot $fixture -WorkflowPath workflow.json -RunId graph-resolve -RuntimeRoot $runtime | ConvertFrom-Json
    if ($graph.status -ne 'RESOLVED' -or $graph.mode -ne 'NATIVE' -or -not $graph.workflowPath.EndsWith('workflow.json')) { throw 'NATIVE resolution contract failed.' }
    $direct = & $pwsh -NoProfile -File $dispatch -Action resolve -ProjectRoot $fixture -RunId direct-resolve -RuntimeRoot $runtime | ConvertFrom-Json
    if ($direct.status -ne 'RESOLVED' -or $direct.mode -ne 'DIRECT') { throw 'DIRECT resolution contract failed.' }
    $inspect = & $pwsh -NoProfile -File $dispatch -Action inspect -ProjectRoot $fixture -WorkflowPath workflow.json -RunId no-checkpoint -RuntimeRoot $runtime | ConvertFrom-Json
    if ($inspect.status -ne 'NOT_FOUND') { throw 'State inspection contract failed.' }
    $worktreeRuntime = Join-Path $fixture '.agentic-harness\runtime'
    $inside = & $pwsh -NoProfile -File $dispatch -Action resolve -ProjectRoot $fixture -WorkflowPath workflow.json -RunId inside-worktree -RuntimeRoot $worktreeRuntime 2>&1
    if ($LASTEXITCODE -eq 0 -or ($inside -join "`n") -notmatch 'outside a Git worktree') { throw 'Dispatcher accepted a RuntimeRoot inside a Git worktree.' }
} finally {
    Remove-Item -LiteralPath $runtime -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'V3 dispatcher tests passed.'
