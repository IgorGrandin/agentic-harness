[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet('All', 'Codex', 'Antigravity')][string]$Runtime = 'All'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
. (Join-Path $PSScriptRoot 'adapter-tools.ps1')

$targets = if ($Runtime -eq 'All') { @('Codex', 'Antigravity') } else { @($Runtime) }
foreach ($target in $targets) {
    $adapter = Get-AdapterManifest -RepositoryRoot $repoRoot -Adapter $target
    $content = Get-AdapterInstructionContent -RepositoryRoot $repoRoot -AdapterManifest $adapter
    $output = Resolve-RepositoryPath -RepositoryRoot $repoRoot -RelativePath $adapter.instructionOutput
    if ($PSCmdlet.ShouldProcess($output, "Materialize $target instructions")) {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $output) | Out-Null
        [IO.File]::WriteAllText($output, $content, [Text.UTF8Encoding]::new($false))
    }
}

Write-Host "Materialized adapter instructions: $($targets -join ', ')."
