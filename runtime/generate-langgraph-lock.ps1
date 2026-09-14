[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$BootstrapPython)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$input = Join-Path $PSScriptRoot 'requirements-langgraph.in'
$output = Join-Path $PSScriptRoot 'requirements-langgraph.lock'
if (-not (Test-Path -LiteralPath $BootstrapPython -PathType Leaf)) { throw "Bootstrap Python was not found: $BootstrapPython" }
$toolRoot = Join-Path ([IO.Path]::GetTempPath()) ('agentic-harness-lock-tools-' + [Guid]::NewGuid().ToString('N'))
try {
    & $BootstrapPython -m venv $toolRoot
    if ($LASTEXITCODE -ne 0) { throw 'Unable to create isolated lock-generation environment.' }
    $toolPython = Join-Path $toolRoot 'Scripts\python.exe'
    & $toolPython -m pip install --disable-pip-version-check pip-tools
    if ($LASTEXITCODE -ne 0) { throw 'Unable to install pip-tools in isolated lock-generation environment.' }
    & $toolPython -m piptools compile --generate-hashes --output-file $output $input
    if ($LASTEXITCODE -ne 0) { throw 'Transitive hash-lock generation failed.' }
} finally {
    if (Test-Path -LiteralPath $toolRoot) { Remove-Item -LiteralPath $toolRoot -Recurse -Force }
}
Write-Host "Generated transitive hash lock: $output"
