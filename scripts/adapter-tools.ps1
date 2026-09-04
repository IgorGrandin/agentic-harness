Set-StrictMode -Version Latest

function Resolve-RepositoryPath {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryRoot,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )

    $root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $path = [IO.Path]::GetFullPath((Join-Path $root ($RelativePath -replace '/', '\')))
    $prefix = $root + [IO.Path]::DirectorySeparatorChar
    if (-not $path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Adapter path escapes repository: $RelativePath"
    }
    return $path
}

function Get-AdapterManifest {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryRoot,
        [Parameter(Mandatory = $true)][string]$Adapter
    )

    $path = Resolve-RepositoryPath -RepositoryRoot $RepositoryRoot -RelativePath "adapters/$($Adapter.ToLowerInvariant())/adapter.json"
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing adapter manifest: $path" }
    return Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
}

function Get-AdapterInstructionContent {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryRoot,
        [Parameter(Mandatory = $true)]$AdapterManifest
    )

    $sources = [Collections.Generic.List[string]]::new()
    foreach ($source in $AdapterManifest.instructionSources) { $sources.Add([string]$source) }

    $parts = foreach ($relative in $sources) {
        $path = Resolve-RepositoryPath -RepositoryRoot $RepositoryRoot -RelativePath $relative
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing instruction source: $relative" }
        (Get-Content -Raw -LiteralPath $path).TrimEnd()
    }

    return (($parts -join "`n`n") + "`n")
}
