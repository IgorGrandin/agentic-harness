[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$script = Join-Path $repoRoot 'skills\azure-devops-card-flow\scripts\new-card-branch.ps1'
$actual = & $script -SpecPath 'backlog/tasks/2528-envio-de-emails-convite-e-senha.md' -NameOnly
if ($actual -ne 'feature/igor.grandin/2528-envio-de-emails-convite-e-senha') { throw "Unexpected branch name: $actual" }
$accentedTitle = ([char]0x00C1) + 'rvore & revis' + ([char]0x00E3) + 'o!'
$override = & $script -WorkItemId 42 -Title $accentedTitle -Owner 'ana.silva' -Prefix 'bugfix' -NameOnly
if ($override -ne 'bugfix/ana.silva/42-arvore-revisao') { throw "Unexpected override branch name: $override" }

$testRoot = Join-Path $repoRoot '.test-output\card-branch-relative-path'
if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force }
New-Item -ItemType Directory -Force -Path $testRoot | Out-Null
git -C $testRoot init --quiet
if ($LASTEXITCODE -ne 0) { throw 'Could not initialize branch-helper test repository.' }
Push-Location $testRoot
try {
    $resolved = & $script -SpecPath 'backlog/tasks/2528-envio-de-emails-convite-e-senha.md' -RepositoryRoot '.' -WhatIf 6>$null
    if ($resolved -ne 'feature/igor.grandin/2528-envio-de-emails-convite-e-senha') { throw "Relative repository root resolved incorrectly: $resolved" }
}
finally { Pop-Location }
Write-Host 'Card branch naming tests passed.'
