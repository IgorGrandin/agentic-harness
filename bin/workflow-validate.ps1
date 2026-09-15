[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$ManifestPath)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-EdgeParts($Edge) {
    if ($Edge -is [string]) {
        $match = [regex]::Match($Edge, '^(?<from>[A-Za-z][A-Za-z0-9_-]*)(?:\((?<condition>[A-Za-z][A-Za-z0-9_-]*)\))?->(?<to>[A-Za-z][A-Za-z0-9_-]*)$')
        if (-not $match.Success) { throw "INVALID_MANIFEST: invalid edge: $Edge" }
        return [pscustomobject]@{ from = $match.Groups['from'].Value; to = $match.Groups['to'].Value; condition = $match.Groups['condition'].Value }
    }
    if ($null -eq $Edge.from -or $null -eq $Edge.to) { throw 'INVALID_MANIFEST: object edge requires from and to' }
    return [pscustomobject]@{ from = [string]$Edge.from; to = [string]$Edge.to; condition = if ($null -eq $Edge.condition) { '' } else { [string]$Edge.condition } }
}
try {
    $m = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json -Depth 32
    foreach ($name in @('schemaVersion','kind','fingerprint','projectRoot','sourceFiles','nodes','edges','policy')) { if ($null -eq $m.PSObject.Properties[$name]) { throw "INVALID_MANIFEST: missing $name" } }
    if ($m.schemaVersion -ne 2 -or $m.kind -ne 'native-workflow-contract' -or $m.mode -ne 'NATIVE' -or [string]$m.fingerprint -notmatch '^[a-f0-9]{64}$') { throw 'INVALID_MANIFEST: unsupported schema, kind, mode, or fingerprint' }
    if (@($m.sourceFiles).Count -eq 0 -or @($m.nodes).Count -eq 0 -or @($m.edges).Count -eq 0) { throw 'INVALID_MANIFEST: sourceFiles, nodes, and edges are required' }
    $sources = @($m.sourceFiles | ForEach-Object { [string]$_ })
    if (($sources | Where-Object { [IO.Path]::IsPathRooted($_) -or $_ -match '(^|[\\/])\.\.([\\/]|$)' } | Measure-Object).Count -gt 0) { throw 'INVALID_MANIFEST: sourceFiles must be project-relative' }
    if (($sources | Sort-Object -Unique).Count -ne $sources.Count) { throw 'INVALID_MANIFEST: duplicate sourceFiles' }
    $projectRoot = [IO.Path]::GetFullPath([string]$m.projectRoot)
    if (-not (Test-Path -LiteralPath $projectRoot -PathType Container)) { throw 'INVALID_MANIFEST: projectRoot does not exist' }
    foreach ($source in $sources) {
        $full = [IO.Path]::GetFullPath((Join-Path $projectRoot $source))
        $prefix = $projectRoot.TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
        if (-not $full.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $full -PathType Leaf)) { throw "INVALID_MANIFEST: declared source is unavailable: $source" }
    }
    $allowedTypes = @('agent','decision','command','finalization')
    $ids = @()
    foreach ($node in @($m.nodes)) {
        $id = [string]$node.id; $type = [string]$node.type
        if ($id -notmatch '^[A-Za-z][A-Za-z0-9_-]*$' -or $type -notin $allowedTypes) { throw 'INVALID_MANIFEST: invalid node id or type' }
        $ids += $id
        if ($type -in @('agent','decision')) {
            if ([string]::IsNullOrWhiteSpace([string]$node.role)) { throw "INVALID_MANIFEST: semantic node $id requires role" }
            if ($node.PSObject.Properties['source'] -and $sources -notcontains ([string]$node.source).Replace('\','/')) { throw "INVALID_MANIFEST: semantic node source is undeclared: $id" }
        }
        if ($type -eq 'command') {
            if ($null -eq $node.command -or [string]::IsNullOrWhiteSpace([string]$node.command.filePath)) { throw "INVALID_MANIFEST: command node $id requires command.filePath" }
            if ($sources -notcontains ([string]$node.command.filePath).Replace('\','/')) { throw "INVALID_MANIFEST: command file is undeclared: $id" }
            if ($null -eq $node.command.arguments) { throw "INVALID_MANIFEST: command node $id requires an arguments array" }
        }
        if ($type -eq 'finalization') {
            if ($null -eq $node.finalization -or [string]::IsNullOrWhiteSpace([string]$node.finalization.manifestPath)) { throw "INVALID_MANIFEST: finalization node $id requires finalization declaration" }
            if ($sources -notcontains ([string]$node.finalization.manifestPath).Replace('\','/')) { throw "INVALID_MANIFEST: finalization manifest is undeclared: $id" }
        }
    }
    if ($m.policy.PSObject.Properties['requiredEvidence']) {
        foreach ($requirement in @($m.policy.requiredEvidence)) {
            if ([string]::IsNullOrWhiteSpace([string]$requirement.id) -or [string]::IsNullOrWhiteSpace([string]$requirement.node) -or [string]$requirement.type -ne 'observed') { throw 'INVALID_MANIFEST: requiredEvidence entries require node, id, and type=observed' }
            $requiredNode = @($m.nodes | Where-Object { $_.id -eq [string]$requirement.node })
            if ($requiredNode.Count -ne 1 -or $requiredNode[0].type -notin @('agent','decision')) { throw "INVALID_MANIFEST: requiredEvidence node is not semantic: $($requirement.node)" }
        }
    }
    if (($ids | Sort-Object -Unique).Count -ne $ids.Count) { throw 'INVALID_MANIFEST: duplicate node id' }
    $edges = @($m.edges | ForEach-Object { Get-EdgeParts $_ })
    foreach ($edge in $edges) {
        if ($edge.from -ne 'START' -and $ids -notcontains $edge.from) { throw "INVALID_MANIFEST: edge source missing: $($edge.from)" }
        if ($ids -notcontains $edge.to) { throw "INVALID_MANIFEST: edge target missing: $($edge.to)" }
    }
    if (($edges | Where-Object from -eq 'START').Count -ne 1) { throw 'INVALID_MANIFEST: exactly one START edge is required' }
    if ($m.policy.reviewBeforeGate -ne $true -or $m.policy.gateFailureBlocksFinalization -ne $true -or $m.policy.rawLogsExternal -ne $true) { throw 'INVALID_MANIFEST: required execution policies are not enabled' }
    $gateIds = @($m.nodes | Where-Object { $_.type -eq 'command' -and (($_.phase -eq 'gate') -or ($_.id -match '(?i)gate')) } | ForEach-Object id)
    $reviewIds = @($m.nodes | Where-Object { $_.type -eq 'decision' -and (($_.role -match '(?i)review') -or ($_.id -match '(?i)review')) } | ForEach-Object id)
    $finalIds = @($m.nodes | Where-Object type -eq 'finalization' | ForEach-Object id)
    foreach ($finalId in $finalIds) {
        foreach ($incoming in @($edges | Where-Object to -eq $finalId)) {
            if ($gateIds -notcontains $incoming.from -or $incoming.condition -ne 'GREEN') { throw 'INVALID_MANIFEST: finalization is allowed only from a GREEN gate edge' }
        }
    }
    foreach ($gateId in $gateIds) {
        $approved = @($edges | Where-Object { $_.to -eq $gateId -and $_.condition -eq 'APPROVED' -and $reviewIds -contains $_.from })
        if ($approved.Count -eq 0) { throw "INVALID_MANIFEST: gate $gateId must be preceded by an APPROVED review edge" }
    }
    foreach ($reviewId in $reviewIds) {
        $finding = @($edges | Where-Object { $_.from -eq $reviewId -and $_.condition -eq 'FINDING' })
        if ($finding.Count -ne 1) { throw "INVALID_MANIFEST: review $reviewId requires exactly one FINDING correction edge" }
        $correctionId = $finding[0].to
        $correction = @($m.nodes | Where-Object id -eq $correctionId)[0]
        if ($null -eq $correction -or $correction.type -ne 'agent') { throw "INVALID_MANIFEST: review $reviewId FINDING target must be an agent correction" }
        $correctionEdges = @($edges | Where-Object from -eq $correctionId)
        if ($correctionEdges.Count -ne 1 -or $correctionEdges[0].condition -or $correctionEdges[0].to -ne $reviewId) { throw "INVALID_MANIFEST: correction $correctionId must route only back to review $reviewId" }
    }
    [ordered]@{ status = 'VALID'; manifestPath = [IO.Path]::GetFullPath($ManifestPath); fingerprint = $m.fingerprint } | ConvertTo-Json -Compress
    exit 0
} catch {
    [ordered]@{ status = 'INVALID_MANIFEST'; error = $_.Exception.Message; manifestPath = [IO.Path]::GetFullPath($ManifestPath) } | ConvertTo-Json -Compress
    exit 1
}
