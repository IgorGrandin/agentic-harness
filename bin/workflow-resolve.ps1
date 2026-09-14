[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ProjectRoot,
    [Parameter(Mandatory = $true)][string]$Alias,
    [string]$RegistryPath = (Join-Path $PSScriptRoot '..\workflows\registry.json'),
    [string]$BindingPath = '.agentic-harness\workflows.json'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Fail([string]$Message) { throw "WORKFLOW_RESOLUTION_FAILED: $Message" }
function Resolve-Local([string]$Root, [string]$Relative) {
    if ([IO.Path]::IsPathRooted($Relative) -or $Relative -match '(^|[\\/])\.\.([\\/]|$)') { Fail "path must be project-relative: $Relative" }
    $full = [IO.Path]::GetFullPath((Join-Path $Root $Relative))
    $prefix = $Root.TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
    if (-not $full.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { Fail "path escapes project root: $Relative" }
    return $full
}

try {
    $root = [IO.Path]::GetFullPath($ProjectRoot)
    if (-not (Test-Path -LiteralPath $root -PathType Container)) { Fail "project root not found: $root" }
    $registryFull = [IO.Path]::GetFullPath($RegistryPath)
    if (-not (Test-Path -LiteralPath $registryFull -PathType Leaf)) { Fail "registry not found: $registryFull" }
    $bindingFull = Resolve-Local $root $BindingPath
    if (-not (Test-Path -LiteralPath $bindingFull -PathType Leaf)) { Fail "binding not found: $BindingPath" }
    $registry = Get-Content -Raw -LiteralPath $registryFull | ConvertFrom-Json -Depth 16
    $binding = Get-Content -Raw -LiteralPath $bindingFull | ConvertFrom-Json -Depth 16
    if ($registry.schemaVersion -ne 1 -or $registry.kind -ne 'workflow-registry' -or $null -eq $registry.aliases -or $null -eq $registry.workflows) { Fail 'invalid registry schema' }
    if ($binding.schemaVersion -ne 1 -or $binding.kind -ne 'workflow-bindings' -or $null -eq $binding.workflows) { Fail 'invalid project binding schema' }
    $normalized = $Alias.Trim()
    $aliasProperty = $registry.aliases.PSObject.Properties[$normalized]
    if ($null -eq $aliasProperty -and $normalized.StartsWith('/')) { $aliasProperty = $registry.aliases.PSObject.Properties[$normalized.TrimStart('/')]; $normalized = $normalized.TrimStart('/') }
    if ($null -eq $aliasProperty) { Fail "alias is not registered: $Alias" }
    $workflowId = [string]$aliasProperty.Value
    $registryWorkflow = $registry.workflows.PSObject.Properties[$workflowId]
    if ($null -eq $registryWorkflow -or $registryWorkflow.Value.mode -ne 'GRAPH') { Fail "registered workflow is not GRAPH: $workflowId" }
    $bindingWorkflow = $binding.workflows.PSObject.Properties[$workflowId]
    if ($null -eq $bindingWorkflow -or [string]::IsNullOrWhiteSpace([string]$bindingWorkflow.Value.definition)) { Fail "binding has no definition for: $workflowId" }
    $definition = Resolve-Local $root ([string]$bindingWorkflow.Value.definition)
    if (-not (Test-Path -LiteralPath $definition -PathType Leaf)) { Fail "workflow definition not found: $($bindingWorkflow.Value.definition)" }
    [ordered]@{ status = 'RESOLVED'; mode = 'GRAPH'; alias = $normalized; workflowId = $workflowId; workflowPath = $definition; bindingPath = $bindingFull; registryPath = $registryFull } | ConvertTo-Json -Compress
} catch {
    [ordered]@{ status = 'FAILED'; error = $_.Exception.Message } | ConvertTo-Json -Compress
    exit 1
}
