[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateRange(1, [int]::MaxValue)][int]$WorkItemId,
    [string]$Title,
    [string]$SpecPath,
    [string]$Owner = 'igor.grandin',
    [string]$Prefix = 'feature',
    [string]$RepositoryRoot = (Get-Location).Path,
    [switch]$NameOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function ConvertTo-BranchSlug([string]$Value) {
    $normalized = $Value.Normalize([Text.NormalizationForm]::FormD)
    $builder = [Text.StringBuilder]::new()
    foreach ($character in $normalized.ToCharArray()) {
        if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($character) -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$builder.Append($character)
        }
    }
    $slug = $builder.ToString().Normalize([Text.NormalizationForm]::FormC).ToLowerInvariant()
    $slug = [regex]::Replace($slug, '[^a-z0-9]+', '-')
    return $slug.Trim('-')
}

$ownerSlug = [regex]::Replace($Owner.ToLowerInvariant(), '[^a-z0-9.]+', '-').Trim('-', '.')
$prefixSlug = ConvertTo-BranchSlug $Prefix
$suffix = if ($SpecPath) {
    [IO.Path]::GetFileNameWithoutExtension($SpecPath).ToLowerInvariant()
} else {
    if ($WorkItemId -lt 1 -or [string]::IsNullOrWhiteSpace($Title)) { throw 'Provide SpecPath, or both WorkItemId and Title.' }
    "$WorkItemId-$(ConvertTo-BranchSlug $Title)"
}
if ($suffix -notmatch '^\d+-[a-z0-9]+(?:-[a-z0-9]+)*$') { throw "Spec filename or generated suffix is not a safe card slug: $suffix" }
if (-not $ownerSlug -or -not $prefixSlug) { throw 'Owner and prefix must produce non-empty branch segments.' }
$branch = "$prefixSlug/$ownerSlug/$suffix"
if ($NameOnly) { Write-Output $branch; return }

$root = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($RepositoryRoot)
$root = [IO.Path]::GetFullPath($root)
if (-not (Test-Path -LiteralPath (Join-Path $root '.git'))) { throw "Not a Git repository root: $root" }
$changes = @(git -C $root status --porcelain)
if ($LASTEXITCODE -ne 0) { throw 'Unable to read Git worktree status.' }
if ($changes.Count -gt 0) { throw 'Refusing to create or switch branches with a dirty worktree.' }

git -C $root show-ref --verify --quiet "refs/heads/$branch"
$exists = ($LASTEXITCODE -eq 0)
$action = if ($exists) { 'Switch to existing card branch' } else { 'Create and switch to card branch' }
if ($PSCmdlet.ShouldProcess($branch, $action)) {
    if ($exists) { git -C $root switch $branch } else { git -C $root switch -c $branch }
    if ($LASTEXITCODE -ne 0) { throw "Git could not activate branch: $branch" }
}
Write-Output $branch
