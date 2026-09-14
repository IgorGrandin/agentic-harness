[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ManifestPath,
    [Parameter(Mandatory = $true)][string]$RunId,
    [string]$RuntimeRoot = (Join-Path ([IO.Path]::GetTempPath()) 'agentic-harness\graphs'),
    [switch]$Resume,
    [switch]$AllowWrite,
    [switch]$AllowCommit
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($RunId -notmatch '^[A-Za-z0-9._-]+$') { throw 'RunId contains unsafe path characters.' }
$harnessRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$python = Join-Path $harnessRoot 'runtime\python\Scripts\python.exe'
if (-not (Test-Path -LiteralPath $python -PathType Leaf)) { throw "Managed LangGraph Python is unavailable: $python" }
$root = [IO.Path]::GetFullPath($RuntimeRoot)
$checkpoint = Join-Path $root ("checkpoints\\$RunId.sqlite")
$output = Join-Path $root ("results\\$RunId.json")
$invoke = @((Join-Path $harnessRoot 'runtime\langgraph_runtime.py'),'--manifest',$ManifestPath,'--run-id',$RunId,'--checkpoint',$checkpoint,'--output',$output,'--runtime-root',(Join-Path $root 'logs'))
if ($Resume) { $invoke += '--resume' }
if ($AllowWrite) { $invoke += '--allow-write' }
if ($AllowCommit) { $invoke += '--allow-commit' }
& $python @invoke
exit $LASTEXITCODE
