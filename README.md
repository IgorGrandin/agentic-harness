# Codex global configuration

Private, portable source of truth for the user's global Codex SDD workflow. This repository intentionally contains only declarative instructions, Markdown memory, reusable roles, user-authored skills, and a sanitized routing fragment.

## What this installs

| Repository path | Local destination |
|---|---|
| `global/AGENTS.md` | `~/.codex/AGENTS.md` |
| `global/memory-bank/` | `~/.codex/memory-bank/` |
| `global/agents/*.toml` | `~/.codex/agents/` |
| `skills/<allowlisted-skill>/` | `~/.agents/skills/` |
| `config/agents.toml` | selected keys merged into `~/.codex/config.toml` |

Codex loads global `AGENTS.md` at the start of a new run. Start a new task after installation or updates.

## Security boundary

Keep this repository private. It does **not** copy the complete `.codex` directory and must never contain authentication, sessions, SQLite databases, logs, caches, attachments, browser state, plugin caches, or machine identity.

The portable configuration is controlled by `portable-manifest.json`. System skills and plugin-installed skills are deliberately excluded and should be installed normally on each computer.

## First installation on another Windows computer

1. Install Codex and sign in normally. Do not copy authentication files from another machine.
2. Clone this private repository.
3. Preview the installation:

   ```powershell
   pwsh -File .\scripts\install.ps1 -WhatIf
   ```

4. Install:

   ```powershell
   pwsh -File .\scripts\install.ps1
   ```

5. Restart Codex or create a new task.

Windows PowerShell 5.1 may be used as `powershell -File ...` when PowerShell 7 (`pwsh`) is unavailable.

## Routine synchronization

Before using a second computer:

```powershell
git pull --ff-only
pwsh -File .\scripts\install.ps1
```

After deliberately changing global memory, roles, instructions, or an allowlisted skill:

```powershell
pwsh -File .\scripts\export.ps1
git diff --check
git diff
git add -- global/ skills/
git commit -m "Update portable Codex configuration"
git push
```

Review the diff before committing. `export.ps1` never exports the full `config.toml`; update `config/agents.toml` manually when the portable routing policy changes.

## Verification

```powershell
pwsh -File .\scripts\verify.ps1
pwsh -File .\tests\test-portability.ps1
```

Verification checks the allowlisted structure, rejects common local-state paths and likely credential values, validates JSON, and parses every PowerShell script. The portability test uses isolated directories to exercise dry-run behavior, backups, installation, config merging, and allowlisted export.

## Backups and recovery

The installer backs up every managed destination before replacing it. Backups are written under:

```text
~/.codex/portable-backups/<timestamp>/
```

Only managed files and directories are touched. The complete `.codex` and `.agents` directories are never replaced.

To recover, close Codex and copy the desired files from the timestamped backup into their original locations.

## Concurrent computers

V1 uses explicit Git synchronization. Avoid exporting and pushing from two computers simultaneously. Pull before exporting; if Markdown conflicts occur, resolve them as normal Git conflicts and preserve both valid decisions when they are not mutually exclusive.

## Cloud environments

The local global configuration does not automatically become repository-local configuration. Project repositories should continue to carry their own `AGENTS.md`, specs, and project memory. For a new local computer, run this installer. For isolated cloud environments, package or provision the global configuration explicitly rather than copying local credentials or state.
