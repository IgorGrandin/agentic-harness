[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$fast = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'adapters\ollama\Modelfile.qwen-local')
$deep = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'adapters\ollama\Modelfile.qwen-local-deep')
$adapter = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'adapters\ollama\adapter.json') | ConvertFrom-Json

if ($adapter.installMode -ne 'always-versioned') { throw 'Ollama adapter is not included in every global installation.' }

if ($fast -notmatch '(?m)^FROM qwen3\.5:9b\s*$') { throw 'qwen-local does not use qwen3.5:9b.' }
if ($fast -notmatch '(?m)^PARAMETER num_ctx 8192\s*$') { throw 'qwen-local does not use 8K context.' }
if ($deep -notmatch '(?m)^FROM qwen3\.5:9b\s*$') { throw 'qwen-local-deep does not use qwen3.5:9b.' }
if ($deep -notmatch '(?m)^PARAMETER num_ctx 16384\s*$') { throw 'qwen-local-deep does not use 16K context.' }
if (($fast + $deep) -match '(?i)(?:[A-Z]:\\|/Users/|/home/|models[\\/]blobs)') { throw 'Ollama adapter contains a machine-specific model path.' }

Write-Host 'Ollama adapter tests passed without requiring Ollama or model weights.'
