[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidateSet('fingerprint','implementation','review','gate-guard','gate','finalization-guard')][string]$Action,
    [Parameter(Mandatory = $true)][string]$ProjectRoot,
    [Parameter(Mandatory = $true)][string]$RunId,
    [string]$RuntimeRoot = (Join-Path ([IO.Path]::GetTempPath()) 'agentic-harness\execute'),
    [string]$ManifestPath = '',
    [ValidateSet('APPROVED','FINDING')][string]$ReviewStatus = '',
    [string]$ReviewerRole = 'reviewer',
    [string[]]$Findings = @(),
    [ValidateSet('GREEN','FAILED')][string]$GateStatus = '',
    [string]$ResultPath = '',
    [long]$DurationMs = 0
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Json([string]$Path, $Value) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null
    [IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 16), [Text.UTF8Encoding]::new($false))
}
function Read-Json([string]$Path) { if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }; return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json -Depth 16 }
function Assert-External([string]$Path) {
    $full = [IO.Path]::GetFullPath($Path); $root = [IO.Path]::GetFullPath($RuntimeRoot)
    $prefix = $root.TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
    if (-not $full.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'Receipt/state path must be outside the declared runtime root.' }
}
function Invoke-Git([string[]]$GitArgs) {
    $out = & git -C $ProjectRoot @GitArgs 2>&1
    if ($LASTEXITCODE -ne 0) { throw "git $($GitArgs -join ' ') failed: $($out -join "`n")" }
    return @($out)
}
function Get-TreeFingerprint {
    $status = (Invoke-Git -GitArgs @('status','--short','--untracked-files=all')) -join "`n"
    $diff = (Invoke-Git -GitArgs @('diff','HEAD','--binary')) -join "`n"
    $parts = [Collections.Generic.List[string]]::new(); $parts.Add($status); $parts.Add($diff)
    foreach ($line in ($status -split "`n")) {
        if ($line.Length -lt 4) { continue }
        $relative = $line.Substring(3).Trim('"')
        if ($relative -match ' -> ') { $relative = $relative.Split(' -> ')[-1] }
        $path = Join-Path $ProjectRoot $relative
        if (Test-Path -LiteralPath $path -PathType Leaf) { $parts.Add($relative); $parts.Add(([IO.File]::ReadAllBytes($path) | ForEach-Object { $_ }) -join ',') }
    }
    $sha = [Security.Cryptography.SHA256]::Create(); $bytes = [Text.Encoding]::UTF8.GetBytes(($parts -join "`n"))
    return ([BitConverter]::ToString($sha.ComputeHash($bytes)) -replace '-','').ToLowerInvariant()
}
function ReceiptPath([string]$Name) { return Join-Path (Join-Path ([IO.Path]::GetFullPath($RuntimeRoot)) $RunId) $Name }

$current = Get-TreeFingerprint
if ($Action -eq 'fingerprint') { [ordered]@{ status='OK'; treeFingerprint=$current; runId=$RunId } | ConvertTo-Json -Compress; exit 0 }
$statePath = ReceiptPath 'state.json'; $state = Read-Json $statePath
if ($null -eq $state) { $state = [ordered]@{ schemaVersion=1; runId=$RunId; workflowId='execute'; phase=$null; completedPhases=@(); implementationTree=$null; reviewTree=$null; reviewStatus=$null; gateTree=$null; gateStatus=$null; manifestFingerprint=$null } }
if ($ManifestPath) { $manifest = Read-Json $ManifestPath; if ($null -eq $manifest) { throw "Manifest not found: $ManifestPath" }; $state.manifestFingerprint = [string]$manifest.fingerprint }
switch ($Action) {
    'implementation' {
        $state.phase='review'; $state.implementationTree=$current; if (@($state.completedPhases) -notcontains 'implementation') { $state.completedPhases += 'implementation' }
        Write-Json $statePath $state; [ordered]@{ status='RECORDED'; treeFingerprint=$current; statePath=$statePath } | ConvertTo-Json -Compress
    }
    'review' {
        if ($ReviewStatus -eq 'FINDING') { $state.reviewStatus='FINDING'; $state.reviewTree=$current; $state.gateTree=$null; $state.gateStatus=$null }
        else { $state.reviewStatus='APPROVED'; $state.reviewTree=$current; $state.phase='gate'; if (@($state.completedPhases) -notcontains 'review') { $state.completedPhases += 'review' } }
        $receipt=[ordered]@{schemaVersion=1;status=$ReviewStatus;treeFingerprint=$current;reviewerRole=$ReviewerRole;createdAt=[DateTimeOffset]::UtcNow.ToString('o');findings=@($Findings)}
        Write-Json (ReceiptPath 'review.receipt.json') $receipt; Write-Json $statePath $state
        [ordered]@{status='RECORDED';receiptPath=(ReceiptPath 'review.receipt.json');treeFingerprint=$current} | ConvertTo-Json -Compress
    }
    'gate-guard' {
        $review=Read-Json (ReceiptPath 'review.receipt.json'); if ($null -eq $review -or $review.status -ne 'APPROVED') { throw 'GATE_BLOCKED: approved review receipt is required.' }; if ($review.treeFingerprint -ne $current) { throw 'GATE_BLOCKED: tree changed after review; re-review is required.' }
        [ordered]@{status='ALLOWED';treeFingerprint=$current} | ConvertTo-Json -Compress
    }
    'gate' {
        & $PSCommandPath -Action gate-guard -ProjectRoot $ProjectRoot -RunId $RunId -RuntimeRoot $RuntimeRoot | Out-Null
        $state.phase='finalization'; $state.gateTree=$current; $state.gateStatus=$GateStatus; if ($GateStatus -eq 'GREEN') { $state.completedPhases += 'gate' }
        $receipt=[ordered]@{schemaVersion=1;status=$GateStatus;treeFingerprint=$current;manifestPath=$ManifestPath;duration=$DurationMs;createdAt=[DateTimeOffset]::UtcNow.ToString('o')}
        Write-Json (ReceiptPath 'gate.receipt.json') $receipt; Write-Json $statePath $state
        if ($GateStatus -ne 'GREEN') { throw 'GATE_FAILED: finalization is blocked.' }
        [ordered]@{status='RECORDED';receiptPath=(ReceiptPath 'gate.receipt.json');treeFingerprint=$current} | ConvertTo-Json -Compress
    }
    'finalization-guard' {
        $gate=Read-Json (ReceiptPath 'gate.receipt.json'); if ($null -eq $gate -or $gate.status -ne 'GREEN') { throw 'FINALIZATION_BLOCKED: green gate receipt is required.' }; if ($gate.treeFingerprint -ne $current) { throw 'FINALIZATION_BLOCKED: tree changed after gate.' }; [ordered]@{status='ALLOWED';treeFingerprint=$current} | ConvertTo-Json -Compress
    }
}
