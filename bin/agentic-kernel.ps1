[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$RequestPath
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

try {
    # Windows PowerShell 5.1 has no ConvertFrom-Json -Depth parameter.
    $request = Get-Content -Raw -LiteralPath $RequestPath | ConvertFrom-Json
    if ($request.schemaVersion -ne 1 -or $request.kind -ne 'kernel-request') { throw 'INVALID_KERNEL_REQUEST: schemaVersion 1 and kind kernel-request are required.' }
    $role = [string]$request.role
    if ($role -notmatch '^[A-Za-z][A-Za-z0-9_-]*$') { throw 'INVALID_KERNEL_REQUEST: role is required.' }
    $contextBudget = [int]$request.budgets.contextTokens
    $outputBudget = [int]$request.budgets.outputTokens
    if ($contextBudget -lt 256 -or $contextBudget -gt 32768 -or $outputBudget -lt 64 -or $outputBudget -gt 8192) { throw 'INVALID_KERNEL_REQUEST: budgets exceed V4 bounds.' }
    $sources = @($request.contextSources | ForEach-Object { [string]$_ })
    if ($sources.Count -eq 0 -or @($sources | Where-Object { [IO.Path]::IsPathRooted($_) -or $_ -match '(^|[\\/])\.\.([\\/]|$)' }).Count -gt 0) { throw 'INVALID_KERNEL_REQUEST: contextSources must be a non-empty relative allowlist.' }
    $failure = if ($request.PSObject.Properties['failure']) { $request.failure } else { $null }
    $status = if ($null -eq $failure) { 'READY' } else { 'REPLACEMENT_REQUIRED' }
    $worker = if ($null -eq $failure) { [string]$request.workerId } else { [string]$failure.workerId }
    if (-not $worker) { $worker = 'worker-1' }
    $replacement = if ($null -eq $failure) { $null } else { [ordered]@{ role=$role; workerId=($worker + '-replacement'); reason=[string]$failure.reason; contextSources=$sources; budgets=[ordered]@{contextTokens=$contextBudget;outputTokens=$outputBudget} } }
    [ordered]@{ status=$status; kernel='v4-single'; root='host-selected'; role=$role; workerId=$worker; constraintsOverlay=([bool]$request.constraintsOverlay); contextSources=$sources; budgets=[ordered]@{contextTokens=$contextBudget;outputTokens=$outputBudget}; replacement=$replacement } | ConvertTo-Json -Compress -Depth 16
    exit 0
} catch {
    [ordered]@{ status='INVALID_KERNEL_REQUEST'; error=$_.Exception.Message } | ConvertTo-Json -Compress
    exit 1
}
