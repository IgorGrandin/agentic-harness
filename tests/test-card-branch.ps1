[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$script = Join-Path $repoRoot 'skills\azure-devops-card-flow\scripts\new-card-branch.ps1'
$actual = & $script -SpecPath 'backlog/tasks/2528-envio-de-emails-convite-e-senha.md' -NameOnly
if ($actual -ne 'feature/igor.grandin/2528-envio-de-emails-convite-e-senha') { throw "Unexpected branch name: $actual" }
$override = & $script -WorkItemId 42 -Title 'Árvore & revisão!' -Owner 'ana.silva' -Prefix 'bugfix' -NameOnly
if ($override -ne 'bugfix/ana.silva/42-arvore-revisao') { throw "Unexpected override branch name: $override" }
Write-Host 'Card branch naming tests passed.'
