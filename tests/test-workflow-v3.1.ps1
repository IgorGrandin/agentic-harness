[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$fixture = Join-Path $repo 'tests\fixtures\workflow-project'
$project = Join-Path ([IO.Path]::GetTempPath()) ('agentic-harness-v31-project-' + [Guid]::NewGuid().ToString('N'))
$pwsh = (Get-Process -Id $PID).Path
$resolver = Join-Path $repo 'bin\workflow-resolve.ps1'
$compiler = Join-Path $repo 'bin\workflow-compile.ps1'
$finalizer = Join-Path $repo 'bin\agentic-finalize.ps1'
$runtime = Join-Path ([IO.Path]::GetTempPath()) ('agentic-harness-v31-' + [Guid]::NewGuid().ToString('N'))
$cache = Join-Path $runtime 'cache'
$externalRoot = Join-Path ([IO.Path]::GetTempPath()) ('agentic-harness-roundlog-' + [Guid]::NewGuid().ToString('N'))
$skillPath = Join-Path $fixture 'implementation.md'
New-Item -ItemType Directory -Force -Path $project | Out-Null
Copy-Item -LiteralPath $fixture -Destination $project -Recurse -Force
$project = Join-Path $project 'workflow-project'
$skillPath = Join-Path $project 'implementation.md'
$skillOriginal = [IO.File]::ReadAllText($skillPath)
& git -C $project init --quiet
& git -C $project config user.email tests@example.invalid
& git -C $project config user.name Tests
& git -C $project add .
& git -C $project commit --quiet -m fixture
New-Item -ItemType Directory -Force -Path $runtime | Out-Null
try {
    $resolved = & $pwsh -NoProfile -File $resolver -ProjectRoot $project -Alias '/execute' | ConvertFrom-Json
    if ($resolved.status -ne 'RESOLVED' -or $resolved.mode -ne 'NATIVE' -or $resolved.workflowId -ne 'execute') { throw 'Registered /execute did not resolve to NATIVE.' }
    $missing = & $pwsh -NoProfile -File $resolver -ProjectRoot $project -Alias '/missing' 2>&1
    if ($LASTEXITCODE -eq 0 -or ($missing -join "`n") -notmatch 'FAILED') { throw 'Missing registered alias did not fail closed.' }
    $missingBinding = & $pwsh -NoProfile -File $resolver -ProjectRoot $project -Alias '/execute' -BindingPath '.agentic-harness\missing.json' 2>&1
    if ($LASTEXITCODE -eq 0 -or ($missingBinding -join "`n") -notmatch 'binding not found') { throw 'Missing workflow binding did not fail closed.' }
    $invalidBindingPath = Join-Path $project '.agentic-harness\invalid.json'
    [IO.File]::WriteAllText($invalidBindingPath, '{"schemaVersion":1,"kind":"workflow-bindings","workflows":{"execute":{"definition":"missing.json"}}}', [Text.UTF8Encoding]::new($false))
    $missingDefinition = & $pwsh -NoProfile -File $resolver -ProjectRoot $project -Alias '/execute' -BindingPath '.agentic-harness\invalid.json' 2>&1
    if ($LASTEXITCODE -eq 0 -or ($missingDefinition -join "`n") -notmatch 'workflow definition not found') { throw 'Missing workflow definition did not fail closed.' }
    $first = & $pwsh -NoProfile -File $compiler -ProjectRoot $project -WorkflowPath workflow.json -CacheRoot $cache | ConvertFrom-Json
    $second = & $pwsh -NoProfile -File $compiler -ProjectRoot $project -WorkflowPath workflow.json -CacheRoot $cache | ConvertFrom-Json
    if ($first.status -ne 'COMPILED' -or $second.status -ne 'CACHE_HIT' -or $second.compilerCalls -ne 0) { throw 'Registered workflow cache contract failed.' }
    [IO.File]::AppendAllText($skillPath, "`ncache invalidation sentinel`n", [Text.UTF8Encoding]::new($false))
    $changed = & $pwsh -NoProfile -File $compiler -ProjectRoot $project -WorkflowPath workflow.json -CacheRoot $cache | ConvertFrom-Json
    if ($changed.status -ne 'COMPILED' -or $changed.fingerprint -eq $first.fingerprint) { throw 'Declared source skill did not invalidate cache.' }

    $manifestPath = Join-Path $runtime 'finalize.json'
    $roundLogPath = Join-Path $externalRoot 'rodadas.csv'
    $manifest = [ordered]@{
        schemaVersion = 1; task = 'v31-round-log'; repositoryRoot = $project
        capture = [ordered]@{ branch = $false; head = $false; status = $false; diffNumstat = $false; showNumstat = $false }
        roundLog = [ordered]@{ enabled = $true; external = $true; allowExternal = $true; path = $roundLogPath; allowedRoots = @($externalRoot); header = 'data_hora_inicio;fase;slug'; record = [ordered]@{ data_hora_inicio = '2026-09-14T00:00:00'; fase = 'execute'; slug = 'v31' } }
        commit = [ordered]@{ enabled = $false; paths = @(); message = '' }
    }
    [IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    $result = & $pwsh -NoProfile -File $finalizer -ManifestPath $manifestPath -AllowWrite | ConvertFrom-Json
    $lines = @(Get-Content -LiteralPath $roundLogPath)
    if ($lines.Count -ne 2 -or $lines[0] -ne 'data_hora_inicio;fase;slug' -or $lines[1] -ne '2026-09-14T00:00:00;execute;v31') { throw 'External round-log did not append literal header and one line.' }
    $manifest.roundLog.allowedRoots = @((Join-Path $runtime 'not-allowed'))
    [IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    $denied = & $pwsh -NoProfile -File $finalizer -ManifestPath $manifestPath -AllowWrite 2>&1
    if ($LASTEXITCODE -eq 0 -or ($denied -join "`n") -notmatch 'allowlist') { throw 'External round-log outside allowlist was accepted.' }
    if ((Get-Content -Raw -LiteralPath $finalizer) -match 'Import-Csv|Export-Csv') { throw 'Round-log implementation still uses CSV cmdlets.' }
} finally {
    [IO.File]::WriteAllText($skillPath, $skillOriginal, [Text.UTF8Encoding]::new($false))
    Remove-Item -LiteralPath $runtime -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $externalRoot -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Split-Path -Parent $project) -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'V3.1 registered workflow and external round-log tests passed.'
