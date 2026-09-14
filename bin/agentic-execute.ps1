[CmdletBinding()]
param(
    [ValidateSet('resolve','start','resume','inspect')][string]$Action = 'resolve',
    [string]$ProjectRoot = (Get-Location).Path,
    [string]$WorkflowPath = '',
    [string]$RunId = '',
    [string]$FilePath = '',
    [string[]]$ArgumentList = @(),
    [string]$WorkingDirectory = '',
    [string]$RuntimeRoot = (Join-Path ([IO.Path]::GetTempPath()) 'agentic-harness\execute'),
    [switch]$AllowWrite,
    [switch]$AllowCommit
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Compact([Parameter(ValueFromPipeline = $true)]$Value) { process { $Value | ConvertTo-Json -Compress -Depth 16 } }
function Resolve-ProjectPath([string]$Value) {
    if (-not $Value) { return '' }
    $full = [IO.Path]::GetFullPath((Join-Path $project $Value))
    $prefix = $project.TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
    if (-not $full.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { throw "Path escapes ProjectRoot: $Value" }
    return $full
}
function Assert-ExternalRuntimeRoot([string]$Path) {
    $probe = [IO.DirectoryInfo]::new([IO.Path]::GetFullPath($Path))
    while ($null -ne $probe) {
        if (Test-Path -LiteralPath (Join-Path $probe.FullName '.git')) { throw "RuntimeRoot must be outside a Git worktree: $($probe.FullName)" }
        $probe = $probe.Parent
    }
}

$project = [IO.Path]::GetFullPath($ProjectRoot)
if (-not (Test-Path -LiteralPath $project -PathType Container)) { throw "ProjectRoot was not found: $project" }
$runtime = [IO.Path]::GetFullPath($RuntimeRoot)
Assert-ExternalRuntimeRoot $runtime
if (-not $RunId) { $RunId = [Guid]::NewGuid().ToString('N') }
if ($RunId -notmatch '^[A-Za-z0-9._-]+$') { throw 'RunId contains unsafe path characters.' }
$harnessRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$workflow = Resolve-ProjectPath $WorkflowPath
$mode = if ($workflow) { 'GRAPH' } else { 'DIRECT' }

if ($Action -eq 'resolve') {
    [ordered]@{ status = 'RESOLVED'; mode = $mode; projectRoot = $project; workflowPath = $workflow; runId = $RunId } | Write-Compact
    exit 0
}
if ($Action -eq 'inspect') {
    $checkpoint = Join-Path $runtime (Join-Path 'checkpoints' "$RunId.sqlite")
    [ordered]@{ status = if (Test-Path -LiteralPath $checkpoint) { 'CHECKPOINT_AVAILABLE' } else { 'NOT_FOUND' }; mode = $mode; runId = $RunId; checkpoint = $checkpoint } | Write-Compact
    exit 0
}

if ($mode -eq 'DIRECT') {
    if ($Action -eq 'resume') { throw 'DIRECT mode has no graph checkpoint; invoke start with an explicit FilePath.' }
    if (-not $FilePath) { throw 'DIRECT mode requires explicit FilePath; dispatcher never invents a command.' }
    $cwd = if ($WorkingDirectory) { Resolve-ProjectPath $WorkingDirectory } else { $project }
    $argumentsFile = Join-Path $runtime (Join-Path 'arguments' "$RunId.json")
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $argumentsFile) | Out-Null
    [IO.File]::WriteAllText($argumentsFile, ($ArgumentList | ConvertTo-Json -Compress), [Text.UTF8Encoding]::new($false))
    & (Join-Path $harnessRoot 'bin\agentic-run.ps1') -FilePath $FilePath -ArgumentsFile $argumentsFile -WorkingDirectory $cwd -RuntimeRoot $runtime -RunId $RunId -Phase 'direct'
    exit $LASTEXITCODE
}

if (-not (Test-Path -LiteralPath $workflow -PathType Leaf)) { throw "Workflow definition was not found: $workflow" }
$manifestPath = Join-Path $runtime (Join-Path 'manifests' "$RunId.json")
$cacheRoot = Join-Path $runtime 'workflow-cache'
if ($Action -eq 'start') {
    & (Join-Path $harnessRoot 'bin\workflow-compile.ps1') -ProjectRoot $project -WorkflowPath $WorkflowPath -CacheRoot $cacheRoot -OutputPath $manifestPath | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Workflow compilation failed.' }
} elseif (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "No compiled manifest exists for run_id=$RunId. Start the workflow before resume."
}
& (Join-Path $harnessRoot 'bin\workflow-validate.ps1') -ManifestPath $manifestPath | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Workflow manifest validation failed.' }
$python = Join-Path $harnessRoot 'runtime\python\Scripts\python.exe'
if (-not (Test-Path -LiteralPath $python -PathType Leaf)) { throw "Managed LangGraph Python is unavailable: $python. Re-run scripts/install.ps1." }
$checkpoint = Join-Path $runtime (Join-Path 'checkpoints' "$RunId.sqlite")
$output = Join-Path $runtime (Join-Path 'results' "$RunId.json")
$invoke = @((Join-Path $harnessRoot 'runtime\langgraph_runtime.py'),'--manifest',$manifestPath,'--run-id',$RunId,'--checkpoint',$checkpoint,'--output',$output,'--runtime-root',(Join-Path $runtime 'logs'))
if ($Action -eq 'resume') { $invoke += '--resume' }
if ($AllowWrite) { $invoke += '--allow-write' }
if ($AllowCommit) { $invoke += '--allow-commit' }
& $python @invoke
exit $LASTEXITCODE
