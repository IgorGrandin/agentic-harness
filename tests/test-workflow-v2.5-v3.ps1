[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$fixtureSource = Join-Path $repo 'tests\fixtures\workflow-project'
$root = Join-Path ([IO.Path]::GetTempPath()) ('agentic-harness-workflow-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $root | Out-Null
$fixture = Join-Path $root 'fixture'
Copy-Item -LiteralPath $fixtureSource -Destination $fixture -Recurse -Force
$compiler = Join-Path $repo 'bin\workflow-compile.ps1'
$validator = Join-Path $repo 'bin\workflow-validate.ps1'
$pwsh = (Get-Process -Id $PID).Path
function Invoke-Compile([string]$Output = '') {
    $invoke = @('-NoProfile','-File',$compiler,'-ProjectRoot',$fixture,'-WorkflowPath','workflow.json','-CacheRoot',$root)
    if ($Output) { $invoke += @('-OutputPath',$Output) }
    & $pwsh @invoke | ConvertFrom-Json
}
try {
    $first = Invoke-Compile; if ($first.status -ne 'COMPILED' -or $first.compilerCalls -ne 1) { throw 'First declarative workflow compilation failed.' }
    $second = Invoke-Compile; if ($second.status -ne 'CACHE_HIT' -or $second.compilerCalls -ne 0 -or $second.fingerprint -ne $first.fingerprint) { throw 'Workflow cache-hit contract failed.' }
    $manifest = Join-Path $root 'manifest.json'; Invoke-Compile $manifest | Out-Null
    $valid = & $pwsh -NoProfile -File $validator -ManifestPath $manifest | ConvertFrom-Json
    if ($valid.status -ne 'VALID') { throw 'Compiled manifest did not validate.' }
    $compiled = Get-Content -Raw -LiteralPath $manifest | ConvertFrom-Json
    $gate = @($compiled.nodes | Where-Object id -eq 'GATE')[0]
    if ($gate.command.cwd -ne '.' -or @($gate.command.arguments).Count -ne 0) { throw 'Compiler changed declared command literals.' }
    $bad = Get-Content -Raw -LiteralPath $manifest | ConvertFrom-Json; $bad.sourceFiles += 'invented.ps1'; $bad | ConvertTo-Json -Depth 32 | Set-Content -LiteralPath (Join-Path $root 'bad.json')
    $invalid = & $pwsh -NoProfile -File $validator -ManifestPath (Join-Path $root 'bad.json') | ConvertFrom-Json; if ($invalid.status -ne 'INVALID_MANIFEST') { throw 'Undeclared source invalidation test was accepted.' }
    $badFinal = Get-Content -Raw -LiteralPath $manifest | ConvertFrom-Json; $badFinal.edges = @($badFinal.edges | Where-Object { $_ -ne 'GATE(GREEN)->FINALIZE' }) + 'IMPLEMENT->FINALIZE'; $badFinal | ConvertTo-Json -Depth 32 | Set-Content -LiteralPath (Join-Path $root 'bad-final.json')
    $invalidFinal = & $pwsh -NoProfile -File $validator -ManifestPath (Join-Path $root 'bad-final.json') | ConvertFrom-Json; if ($invalidFinal.status -ne 'INVALID_MANIFEST') { throw 'Unsafe finalization edge was accepted.' }
    $badTopology = Get-Content -Raw -LiteralPath $manifest | ConvertFrom-Json; $badTopology.edges = @($badTopology.edges | ForEach-Object { if ($_ -eq 'REVIEW(FINDING)->CORRECTION') { 'REVIEW(FINDING)->GATE' } else { $_ } }); $badTopology | ConvertTo-Json -Depth 32 | Set-Content -LiteralPath (Join-Path $root 'bad-topology.json')
    $invalidTopology = & $pwsh -NoProfile -File $validator -ManifestPath (Join-Path $root 'bad-topology.json') | ConvertFrom-Json; if ($invalidTopology.status -ne 'INVALID_MANIFEST') { throw 'Finding bypass topology was accepted.' }
    [IO.File]::AppendAllText((Join-Path $fixture 'review.md'), "`ntransitive fingerprint sentinel`n", [Text.UTF8Encoding]::new($false))
    $changed = Invoke-Compile; if ($changed.status -ne 'COMPILED' -or $changed.fingerprint -eq $first.fingerprint) { throw 'Declared dependency did not invalidate fingerprint.' }
} finally {
    Remove-Item -LiteralPath $root -Recurse -Force
}
Write-Host 'V2.5/V3 declarative workflow tests passed.'
