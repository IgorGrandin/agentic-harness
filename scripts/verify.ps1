[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$manifestPath = Join-Path $repoRoot 'portable-manifest.json'
$errors = [Collections.Generic.List[string]]::new()

try { $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json }
catch { $errors.Add("Invalid portable-manifest.json: $($_.Exception.Message)"); $manifest = $null }

$required = @(
    'README.md',
    'global\AGENTS.md',
    'core\policies\context-memory.md',
    'core\policies\deterministic-execution.md',
    'core\policies\session-lifecycle.md',
    'core\policies\evidence.md',
    'core\policies\security-permissions.md',
    'profiles\coder\PROFILE.md',
    'profiles\assistant\PROFILE.md',
    'profiles\knowledge\PROFILE.md',
    'profiles\home\PROFILE.md',
    'profiles\registry.json',
    'adapters\codex\adapter.json',
    'adapters\cursor\adapter.json',
    'adapters\cursor\rules\agentic-harness.mdc',
    'adapters\antigravity\adapter.json',
    'adapters\antigravity\GEMINI.md',
    'adapters\ollama\adapter.json',
    'adapters\ollama\Modelfile.qwen-local',
    'adapters\ollama\Modelfile.qwen-local-deep',
    'mcp\registry.json',
    'memory\domains.md',
    'config\agents.toml',
    'scripts\adapter-tools.ps1',
    'scripts\materialize.ps1',
    'scripts\install.ps1',
    'scripts\install-azure-devops-mcp.ps1',
    'scripts\select-executor.ps1',
    'scripts\export.ps1',
    'scripts\verify.ps1'
    ,'bin\agentic-run.ps1'
    ,'bin\agentic-finalize.ps1'
)
foreach ($relative in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $relative))) { $errors.Add("Missing required path: $relative") }
}

if ($null -ne $manifest) {
    if ($manifest.schemaVersion -ne 4) { $errors.Add("Unsupported manifest schema version: $($manifest.schemaVersion)") }
    foreach ($name in $manifest.corePolicyFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $repoRoot "core\policies\$name"))) { $errors.Add("Missing core policy: $name") }
    }
    foreach ($name in $manifest.profileFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $repoRoot "profiles\$name"))) { $errors.Add("Missing profile file: $name") }
    }
    foreach ($name in $manifest.adapterManifests) {
        if (-not (Test-Path -LiteralPath (Join-Path $repoRoot "adapters\$name"))) { $errors.Add("Missing adapter manifest: $name") }
    }
    foreach ($name in $manifest.harnessInstall.directories) {
        if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $name) -PathType Container)) { $errors.Add("Missing platform directory: $name") }
    }
    foreach ($name in $manifest.harnessInstall.files) {
        if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $name) -PathType Leaf)) { $errors.Add("Missing platform file: $name") }
    }
    foreach ($adapterName in @('codex', 'cursor', 'antigravity')) {
        $adapterManifest = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "adapters\$adapterName\adapter.json") | ConvertFrom-Json
        if ($adapterManifest.installMode -ne 'always') { $errors.Add("Adapter '$adapterName' is not configured for global installation.") }
    }
    $ollamaManifest = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'adapters\ollama\adapter.json') | ConvertFrom-Json
    if ($ollamaManifest.installMode -ne 'always-versioned') { $errors.Add('Ollama adapter is not configured for versioned global installation.') }
    foreach ($name in $manifest.memoryFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $repoRoot "global\memory-bank\$name"))) { $errors.Add("Missing memory file: $name") }
    }
    foreach ($name in $manifest.agentFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $repoRoot "global\agents\$name"))) { $errors.Add("Missing agent file: $name") }
    }
    foreach ($name in $manifest.skills) {
        if (-not (Test-Path -LiteralPath (Join-Path $repoRoot "skills\$name\SKILL.md"))) { $errors.Add("Missing skill entrypoint: $name/SKILL.md") }
    }
}

$forbiddenPath = '(?i)(^|[\\/])(auth\.json|sessions|cache|attachments|browser-state|\.sandbox|\.sandbox-secrets|models[\\/]blobs)([\\/]|$)|\.sqlite(?:-(?:shm|wal))?$|\.jsonl$|installation_id$|\.codex-global-state\.json|\.(?:gguf|safetensors)$'
$secretPatterns = @(
    '(?i)github_pat_[A-Za-z0-9_]{20,}',
    '(?i)gh[pousr]_[A-Za-z0-9]{20,}',
    '(?i)sk-[A-Za-z0-9]{20,}',
    '(?im)^\s*(?:api[_-]?key|access[_-]?token|password|secret)\s*=\s*["''][^"''${}<>]{8,}["'']\s*$'
)

$files = Get-ChildItem -LiteralPath $repoRoot -Force |
    Where-Object { $_.Name -notin @('.git', '.test-output', 'portable-backups') } |
    ForEach-Object {
        if ($_.PSIsContainer) { Get-ChildItem -LiteralPath $_.FullName -Recurse -File -Force }
        else { $_ }
    }
foreach ($file in $files) {
    $relative = $file.FullName.Substring($repoRoot.Length).TrimStart('\', '/')
    if ($relative -match $forbiddenPath) { $errors.Add("Forbidden local-state path: $relative") }

    if ($file.Extension -in @('.md', '.toml', '.json', '.ps1', '.yaml', '.yml')) {
        $content = Get-Content -Raw -LiteralPath $file.FullName
        foreach ($pattern in $secretPatterns) {
            if ($content -match $pattern) { $errors.Add("Possible credential value in: $relative"); break }
        }
    }
}

foreach ($jsonFile in ($files | Where-Object { $_.Extension -eq '.json' })) {
    try { [void](Get-Content -Raw -LiteralPath $jsonFile.FullName | ConvertFrom-Json) }
    catch { $relative = $jsonFile.FullName.Substring($repoRoot.Length).TrimStart('\', '/'); $errors.Add("Invalid JSON in ${relative}: $($_.Exception.Message)") }
}

foreach ($script in (Get-ChildItem -LiteralPath $repoRoot -Filter '*.ps1' -File -Recurse | Where-Object { $_.FullName -notmatch '\\.test-output\\' })) {
    $tokens = $null
    $parseErrors = $null
    [void][Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$tokens, [ref]$parseErrors)
    foreach ($parseError in $parseErrors) { $errors.Add("PowerShell syntax error in $($script.Name): $($parseError.Message)") }
}

. (Join-Path $PSScriptRoot 'adapter-tools.ps1')
foreach ($adapterName in @('Codex', 'Cursor', 'Antigravity')) {
    try {
        $adapter = Get-AdapterManifest -RepositoryRoot $repoRoot -Adapter $adapterName
        $expected = Get-AdapterInstructionContent -RepositoryRoot $repoRoot -AdapterManifest $adapter
        $output = Resolve-RepositoryPath -RepositoryRoot $repoRoot -RelativePath $adapter.instructionOutput
        if (-not (Test-Path -LiteralPath $output -PathType Leaf)) { $errors.Add("Missing materialized $adapterName instructions: $($adapter.instructionOutput)"); continue }
        $actual = Get-Content -Raw -LiteralPath $output
        if ($actual -ne $expected) { $errors.Add("Materialized $adapterName instructions are stale. Run scripts/materialize.ps1.") }
    }
    catch { $errors.Add("Invalid $adapterName adapter: $($_.Exception.Message)") }
}

$coreContent = Get-ChildItem -LiteralPath (Join-Path $repoRoot 'core\policies') -Filter '*.md' -File |
    ForEach-Object { Get-Content -Raw -LiteralPath $_.FullName }
if (($coreContent -join "`n") -match '(?i)\b(?:Sol|Luna|Terra|Codex|Antigravity|Ollama|Qwen)\b') {
    $errors.Add('Universal Core policies contain runtime- or model-specific routing.')
}

$coderContent = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'profiles\coder\PROFILE.md')
if ($coderContent -match '(?i)\b(?:GPT|Gemini|Claude|Sol|Luna|Terra|Codex|Cursor|Antigravity|Ollama|Qwen)\b') {
    $errors.Add('Coder profile contains runtime- or model-specific routing.')
}

try {
    $profiles = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'profiles\registry.json') | ConvertFrom-Json
    $capabilities = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'mcp\registry.json') | ConvertFrom-Json
    foreach ($profileProperty in $profiles.profiles.PSObject.Properties) {
        if ($profileProperty.Value.required -ne $true) { $errors.Add("Profile '$($profileProperty.Name)' is not declared as a permanent harness profile.") }
        foreach ($capability in $profileProperty.Value.capabilities) {
            $capabilityProperty = $capabilities.capabilities.PSObject.Properties[$capability]
            if ($null -eq $capabilityProperty) { $errors.Add("Profile '$($profileProperty.Name)' declares unknown capability '$capability'."); continue }
            if ($profileProperty.Name -notin $capabilityProperty.Value.allowedProfiles) {
                $errors.Add("Capability '$capability' does not allow declared profile '$($profileProperty.Name)'.")
            }
        }
    }
}
catch { $errors.Add("Invalid profile/capability registry: $($_.Exception.Message)") }

$fastModel = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'adapters\ollama\Modelfile.qwen-local')
$deepModel = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'adapters\ollama\Modelfile.qwen-local-deep')
if ($fastModel -notmatch '(?m)^FROM qwen3\.5:9b\s*$' -or $fastModel -notmatch '(?m)^PARAMETER num_ctx 8192\s*$') { $errors.Add('Invalid qwen-local Modelfile.') }
if ($deepModel -notmatch '(?m)^FROM qwen3\.5:9b\s*$' -or $deepModel -notmatch '(?m)^PARAMETER num_ctx 16384\s*$') { $errors.Add('Invalid qwen-local-deep Modelfile.') }

$agentConfig = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'config\agents.toml')
foreach ($expected in @('max_concurrent_threads_per_session', 'enabled', 'default_subagent_model', 'default_subagent_reasoning_effort', 'interrupt_message')) {
    if ($agentConfig -notmatch "(?m)^\s*$([regex]::Escape($expected))\s*=") { $errors.Add("Missing portable agent setting: $expected") }
}

$codexRuntime = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'adapters\codex\runtime.md')
$modelRouting = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'skills\sdd-workflow\references\model-routing.md')
$executionPolicy = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'core\policies\deterministic-execution.md')
foreach ($marker in @('orchestrator is a role', 'Luna Medium', 'Luna Max', 'Terra High', 'Sol Low', 'Sol Medium', 'Sol High')) {
    if (-not (($codexRuntime + $modelRouting).Contains($marker))) { $errors.Add("Routing policy missing: $marker") }
}
foreach ($marker in @('every first Sol escalation MUST use Sol Low', 'MUST NOT skip rungs', 'Medium is allowed only after Low', 'High is allowed only after Medium')) {
    if (-not (($codexRuntime + $modelRouting).Contains($marker))) { $errors.Add("Sequential Sol escalation policy missing: $marker") }
}
foreach ($marker in @('MUST use it', 'repeatedly asking for status', 'Preserve commands', 'agentic-run.ps1', 'agentic-finalize.ps1')) {
    if (-not $executionPolicy.Contains($marker)) { $errors.Add("Deterministic execution policy missing: $marker") }
}
if ($agentConfig -notmatch '(?m)^max_concurrent_threads_per_session\s*=\s*3\s*$') { $errors.Add('Codex maximum concurrent subagents must remain 3.') }
if ($modelRouting -notmatch 'fork_turns: "none"' -or $modelRouting -notmatch 'Never use `fork_turns: "all"` when selecting Luna or Terra') { $errors.Add('Bounded-context model-switch policy is missing.') }

if ($errors.Count -gt 0) {
    foreach ($message in $errors) { Write-Error $message }
    exit 1
}

Write-Host "Verification passed: $($files.Count) portable files checked."
exit 0
