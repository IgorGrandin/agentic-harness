[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ProjectRoot,
    [Parameter(Mandatory = $true)][string]$WorkflowPath,
    [string]$CacheRoot = (Join-Path ([IO.Path]::GetTempPath()) 'agentic-harness\workflow-cache'),
    [string]$OutputPath = '',
    [switch]$Force
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Json([string]$Path, $Value) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null
    [IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 32), [Text.UTF8Encoding]::new($false))
}
function Get-RelativePath([string]$Value, [string]$ProjectFull) {
    if ([string]::IsNullOrWhiteSpace($Value) -or [IO.Path]::IsPathRooted($Value)) { throw "INVALID_MANIFEST: source must be a relative non-empty path: $Value" }
    $full = [IO.Path]::GetFullPath((Join-Path $ProjectFull $Value))
    $prefix = $ProjectFull.TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
    if (-not $full.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { throw "INVALID_MANIFEST: source escapes project root: $Value" }
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { throw "INVALID_MANIFEST: missing declared source: $Value" }
    return [pscustomobject]@{ relative = $Value.Replace('\','/'); full = $full }
}
function Get-Fingerprint($Sources) {
    $builder = [Text.StringBuilder]::new()
    foreach ($source in $Sources | Sort-Object relative) {
        [void]$builder.Append($source.relative).Append("`n")
        [void]$builder.Append(([IO.File]::ReadAllText($source.full)).Replace("`r`n", "`n").Replace("`r", "`n")).Append("`n")
    }
    $bytes = [Text.Encoding]::UTF8.GetBytes($builder.ToString())
    $sha = [Security.Cryptography.SHA256]::Create()
    return ([BitConverter]::ToString($sha.ComputeHash($bytes)) -replace '-','').ToLowerInvariant()
}

try {
    $root = [IO.Path]::GetFullPath($ProjectRoot)
    if (-not (Test-Path -LiteralPath $root -PathType Container)) { throw "ProjectRoot was not found: $root" }
    $definitionSource = Get-RelativePath -Value $WorkflowPath -ProjectFull $root
    $definition = Get-Content -Raw -LiteralPath $definitionSource.full | ConvertFrom-Json -Depth 32
    if ($definition.schemaVersion -ne 1 -or $definition.kind -ne 'workflow-definition') { throw 'INVALID_MANIFEST: workflow definition requires schemaVersion 1 and kind workflow-definition' }
    if ($null -eq $definition.sourceFiles -or @($definition.sourceFiles).Count -eq 0) { throw 'INVALID_MANIFEST: workflow definition must declare sourceFiles' }
    if ($null -eq $definition.nodes -or @($definition.nodes).Count -eq 0 -or $null -eq $definition.edges -or $null -eq $definition.policy) { throw 'INVALID_MANIFEST: workflow definition requires nodes, edges, and policy' }

    # All dependencies must be explicitly listed by the definition. The compiler
    # does not infer files from project conventions or command text.
    $declared = @($definition.sourceFiles | ForEach-Object { [string]$_ })
    $sources = @($definitionSource) + @($declared | ForEach-Object { Get-RelativePath -Value $_ -ProjectFull $root })
    $duplicates = @($sources | Group-Object relative | Where-Object Count -gt 1)
    if ($duplicates.Count -gt 0) { throw "INVALID_MANIFEST: duplicate source: $($duplicates[0].Name)" }
    $sourceNames = @($sources | ForEach-Object relative)
    foreach ($node in @($definition.nodes)) {
        if ($node.PSObject.Properties['source'] -and $sourceNames -notcontains ([string]$node.source).Replace('\','/')) { throw "INVALID_MANIFEST: node source is not declared: $($node.source)" }
        if ($node.PSObject.Properties['command']) {
            $filePath = [string]$node.command.filePath
            if ($sourceNames -notcontains $filePath.Replace('\','/')) { throw "INVALID_MANIFEST: command filePath is not a declared source: $filePath" }
        }
    }

    $fingerprint = Get-Fingerprint $sources
    New-Item -ItemType Directory -Force -Path $CacheRoot | Out-Null
    $cachePath = Join-Path ([IO.Path]::GetFullPath($CacheRoot)) "$fingerprint.manifest.json"
    if (-not $Force -and (Test-Path -LiteralPath $cachePath)) {
        $cached = Get-Content -Raw -LiteralPath $cachePath | ConvertFrom-Json -Depth 32
        if ($OutputPath) { Write-Json -Path ([IO.Path]::GetFullPath($OutputPath)) -Value $cached }
        [ordered]@{ status = 'CACHE_HIT'; fingerprint = $fingerprint; manifestPath = if ($OutputPath) { [IO.Path]::GetFullPath($OutputPath) } else { $cachePath }; compilerCalls = 0; sourceFiles = @($cached.sourceFiles) } | ConvertTo-Json -Compress -Depth 32
        exit 0
    }
    $manifest = [ordered]@{
        schemaVersion = 2; kind = 'native-workflow-contract'; fingerprint = $fingerprint; projectRoot = $root; mode = 'NATIVE'
        sourceFiles = $sourceNames; nodes = @($definition.nodes); edges = @($definition.edges); policy = $definition.policy
        routing = if ($definition.PSObject.Properties['routing']) { $definition.routing } else { [ordered]@{} }
    }
    $temporary = Join-Path ([IO.Path]::GetTempPath()) ('agentic-harness-manifest-' + [Guid]::NewGuid().ToString('N') + '.json')
    try {
        Write-Json -Path $temporary -Value $manifest
        $validator = Join-Path $PSScriptRoot 'workflow-validate.ps1'
        & (Get-Process -Id $PID).Path -NoProfile -File $validator -ManifestPath $temporary | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'INVALID_MANIFEST: declared workflow failed validation' }
    } finally { Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue }
    Write-Json -Path $cachePath -Value $manifest
    if ($OutputPath) { Write-Json -Path ([IO.Path]::GetFullPath($OutputPath)) -Value $manifest }
    [ordered]@{ status = 'COMPILED'; fingerprint = $fingerprint; manifestPath = if ($OutputPath) { [IO.Path]::GetFullPath($OutputPath) } else { $cachePath }; compilerCalls = 1; sourceFiles = $sourceNames } | ConvertTo-Json -Compress -Depth 32
} catch {
    [ordered]@{ status = 'INVALID_MANIFEST'; error = $_.Exception.Message } | ConvertTo-Json -Compress
    exit 1
}
