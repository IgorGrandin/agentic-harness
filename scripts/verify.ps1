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
    'config\agents.toml',
    'scripts\install.ps1',
    'scripts\export.ps1',
    'scripts\verify.ps1'
)
foreach ($relative in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $relative))) { $errors.Add("Missing required path: $relative") }
}

if ($null -ne $manifest) {
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

$forbiddenPath = '(?i)(^|[\\/])(auth\.json|sessions|cache|attachments|\.sandbox|\.sandbox-secrets)([\\/]|$)|\.sqlite(?:-(?:shm|wal))?$|\.jsonl$|installation_id$|\.codex-global-state\.json'
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

foreach ($script in (Get-ChildItem -LiteralPath (Join-Path $repoRoot 'scripts') -Filter '*.ps1' -File)) {
    $tokens = $null
    $parseErrors = $null
    [void][Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$tokens, [ref]$parseErrors)
    foreach ($parseError in $parseErrors) { $errors.Add("PowerShell syntax error in $($script.Name): $($parseError.Message)") }
}

$agentConfig = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'config\agents.toml')
foreach ($expected in @('max_concurrent_threads_per_session', 'enabled', 'default_subagent_model', 'default_subagent_reasoning_effort', 'interrupt_message')) {
    if ($agentConfig -notmatch "(?m)^\s*$([regex]::Escape($expected))\s*=") { $errors.Add("Missing portable agent setting: $expected") }
}

if ($errors.Count -gt 0) {
    foreach ($message in $errors) { Write-Error $message }
    exit 1
}

Write-Host "Verification passed: $($files.Count) portable files checked."
exit 0
