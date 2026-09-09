[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][ValidateSet('Cursor', 'Codex', 'Antigravity')][string]$Executor,
    [string]$ProjectRoot = (Get-Location).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = [IO.Path]::GetFullPath($ProjectRoot)
if (-not (Test-Path -LiteralPath $root -PathType Container)) { throw "Project root does not exist: $root" }
$target = Join-Path $root '.agentic-harness\executor.json'
$payload = [ordered]@{
    schemaVersion = 1
    profile = 'coder'
    executor = $Executor.ToLowerInvariant()
} | ConvertTo-Json

if ($PSCmdlet.ShouldProcess($target, "Select $Executor as the project Coder executor")) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
    [IO.File]::WriteAllText($target, "$payload`n", [Text.UTF8Encoding]::new($false))
}

Write-Host "Coder executor selected: $Executor ($target)"
