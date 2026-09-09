[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][ValidatePattern('^[A-Za-z0-9][A-Za-z0-9-]{1,63}$')][string]$Organization,
    [string]$NpxCommand = 'npx',
    [string]$CodexHome = $(if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path ([Environment]::GetFolderPath('UserProfile')) '.codex' }),
    [string]$CursorHome = $(Join-Path ([Environment]::GetFolderPath('UserProfile')) '.cursor'),
    [string]$GeminiHome = $(Join-Path ([Environment]::GetFolderPath('UserProfile')) '.gemini')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$arguments = @('-y', '@azure-devops/mcp', $Organization, '-d', 'core', 'work', 'work-items', 'repositories')
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'

function Backup-File([string]$Path, [string]$Root) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return }
    $backup = Join-Path $Root "portable-backups\$timestamp\$(Split-Path -Leaf $Path)"
    if ($PSCmdlet.ShouldProcess($Path, "Back up to $backup")) {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $backup) | Out-Null
        Copy-Item -LiteralPath $Path -Destination $backup -Force
    }
}

function Install-JsonMcp([string]$Root, [string]$RelativePath) {
    $path = Join-Path $Root $RelativePath
    $config = if (Test-Path -LiteralPath $path) { Get-Content -Raw -LiteralPath $path | ConvertFrom-Json } else { [pscustomobject]@{} }
    if (-not $config.PSObject.Properties['mcpServers']) { $config | Add-Member -NotePropertyName mcpServers -NotePropertyValue ([pscustomobject]@{}) }
    $server = [pscustomobject]@{ command = $NpxCommand; args = $arguments }
    $config.mcpServers | Add-Member -NotePropertyName 'azure-devops' -NotePropertyValue $server -Force
    Backup-File -Path $path -Root $Root
    if ($PSCmdlet.ShouldProcess($path, 'Merge Azure DevOps MCP configuration')) {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $path) | Out-Null
        [IO.File]::WriteAllText($path, (($config | ConvertTo-Json -Depth 20) + "`n"), [Text.UTF8Encoding]::new($false))
    }
}

function Install-CodexMcp {
    $path = Join-Path $CodexHome 'config.toml'
    $lines = if (Test-Path -LiteralPath $path) { [Collections.Generic.List[string]]@(Get-Content -LiteralPath $path) } else { [Collections.Generic.List[string]]::new() }
    $output = [Collections.Generic.List[string]]::new()
    $skip = $false
    foreach ($line in $lines) {
        if ($line -match '^\s*\[mcp_servers\.azure-devops\]\s*$') { $skip = $true; continue }
        if ($skip -and $line -match '^\s*\[') { $skip = $false }
        if (-not $skip) { $output.Add($line) }
    }
    while ($output.Count -gt 0 -and [string]::IsNullOrWhiteSpace($output[$output.Count - 1])) { $output.RemoveAt($output.Count - 1) }
    if ($output.Count -gt 0) { $output.Add('') }
    $escapedCommand = $NpxCommand.Replace("'", "''")
    $quotedArgs = ($arguments | ForEach-Object { '"' + $_.Replace('\', '\\').Replace('"', '\"') + '"' }) -join ', '
    $output.Add('[mcp_servers.azure-devops]')
    $output.Add("command = '$escapedCommand'")
    $output.Add("args = [$quotedArgs]")
    Backup-File -Path $path -Root $CodexHome
    if ($PSCmdlet.ShouldProcess($path, 'Merge Azure DevOps MCP configuration')) {
        New-Item -ItemType Directory -Force -Path $CodexHome | Out-Null
        [IO.File]::WriteAllLines($path, $output, [Text.UTF8Encoding]::new($false))
    }
}

Install-CodexMcp
Install-JsonMcp -Root $CursorHome -RelativePath 'mcp.json'
Install-JsonMcp -Root $GeminiHome -RelativePath 'config\mcp_config.json'

Write-Host "Azure DevOps MCP configured for organization '$Organization' in Codex, Cursor, and Antigravity."
Write-Host 'Authentication is interactive on first tool use; no credential was stored by this script.'
