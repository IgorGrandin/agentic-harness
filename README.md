# Agentic Harness

Private, portable, Markdown-first source of truth for a runtime- and model-agnostic agentic harness. Cursor is the default coding executor; Codex and Antigravity remain interchangeable executors of the same Coder profile.

## Architecture

```text
Core (policy, lifecycle, evidence, security, deterministic execution)
  + Profiles (coder, assistant, knowledge, home)
  + Shared assets (memory, skills, workflows, role definitions, MCP registry)
  + Adapters (cursor, codex, antigravity, ollama)
```

- **Core** contains universal policy and never names a runtime or model.
- **Profiles** define roles, constraints, methods, testing, review, documentation, and done criteria.
- **Adapters** translate profiles and shared assets into native runtime files and paths.
- **Models** are runtime choices. They are never identities of profiles.

Adding a future executor should require a small adapter, installer wiring, and tests—not a copy of the harness.

## Repository layout

- `core/policies/`: shared operating policy.
- `profiles/coder/`: executor-agnostic software-engineering profile.
- `profiles/{assistant,knowledge,home}/`: other permanent profiles.
- `skills/`: canonical Agent Skills source.
- `global/memory-bank/`: canonical global Markdown memory.
- `global/agents/`: canonical reusable role definitions.
- `adapters/{cursor,codex,antigravity,ollama}/`: minimal runtime translations.
- `mcp/registry.json`: capability declarations, never credentials or connection state.
- `scripts/`: materialization, installation, export, executor selection, and verification.
- `bin/`: portable blocking execution and mechanical finalization entrypoints.
- `tests/`: isolated smoke and portability tests.

## Materialization and installation

```powershell
pwsh -File .\scripts\materialize.ps1
pwsh -File .\scripts\verify.ps1
pwsh -File .\scripts\install.ps1 -WhatIf
pwsh -File .\scripts\install.ps1
```

Materialization composes the same Core and profile Markdown into Codex `AGENTS.md`, a Cursor `.mdc` global rule, and Antigravity `GEMINI.md`. The installer is allowlisted, repeatable, path-checked, and backs up managed targets. It does not install runtimes, download models, authenticate MCP, change Cursor account rules, or install hooks.

### Installed locations

- Shared harness snapshot: `~/.agentic-harness/`
- Stable runner entrypoints: `~/.agentic-harness/bin/agentic-run.ps1` and `agentic-finalize.ps1`
- Shared Cursor/Codex skills: `~/.agents/skills/`
- Codex: `~/.codex/AGENTS.md`, `memory-bank/`, `agents/*.toml`, and merged `[agents]` settings
- Cursor: `~/.cursor/rules/agentic-harness.mdc`, `memory-bank/`, and generated `agents/*.md`
- Antigravity: `~/.gemini/GEMINI.md` and `config/skills/`

Copies are used instead of Windows links. This avoids Developer Mode and privilege dependencies. Re-run installation after pulling changes.

`agentic-run.ps1` receives an explicit executable plus arguments, waits internally through success, failure, or timeout, stores stdout/stderr and run state under the machine temporary directory by default, and emits one compact JSON result. Arguments are not persisted, and log tails are opt-in. `agentic-finalize.ps1` captures Git metadata from a small JSON manifest; round-log writes require `-AllowWrite`, while staging and commit require both manifest intent and `-AllowCommit`. Project instructions remain authoritative for command and finalization semantics.

## Cursor

Cursor discovers global skills from `~/.agents/skills/`, project rules from `.cursor/rules/`, plain project `AGENTS.md`, and user subagents from `~/.cursor/agents/`. The adapter generates native `.md` subagents from shared role definitions.

Use project `AGENTS.md` for cross-executor instructions and `.cursor/rules/*.mdc` only for Cursor-specific scoping. MCP remains user/project managed in `~/.cursor/mcp.json` or `.cursor/mcp.json`. Hooks are opt-in: add `.cursor/hooks.json` only when the repository already has fast, deterministic commands.

## Codex and Antigravity

Codex continues to receive the complete Coder composition and native TOML roles/config. Codex-specific model routing stays in its adapter. Antigravity receives Core plus Coder, Assistant, Knowledge, and Home in `GEMINI.md`, plus the same allowlisted skills under its native global path.

## Choosing the Coder executor

The task-level choice is simply the runtime used. An explicit choice always wins. To record a project default:

```powershell
pwsh -File C:\path\to\agentic-harness\scripts\select-executor.ps1 -Executor Cursor -ProjectRoot C:\path\to\project
```

Use `Codex` or `Antigravity` instead when desired. This writes `.agentic-harness/executor.json`; it does not launch a runtime or bind a model.

## Azure DevOps card funnel

Use the shared `azure-devops-card-flow` skill for Azure Boards work. The already generated and committed `backlog/tasks/<id>-<slug>.md` is the normal input and local execution contract. Executors must locate and complement that file, never create a duplicate for the same card. Both **In scope** and **Out of scope** are mandatory before planning or editing. Complex or legacy-dependent cards receive a read-only scout investigation, Cursor performs approved planning/build, and Codex performs independent review when the risk gate requires it.

Azure DevOps access is optional during normal execution. Use the MCP only when the local spec is missing or may be stale, live comments/attachments/state are needed, or the user explicitly requests a board operation.

Before Build, derive the branch from the card: `feature/igor.grandin/<id>-<slug>`. The shared helper normalizes accents and punctuation and refuses to switch branches in a dirty worktree:

```powershell
pwsh -File .\skills\azure-devops-card-flow\scripts\new-card-branch.ps1 -SpecPath .\backlog\tasks\2528-envio-de-emails-convite-e-senha.md
```

Configure the official MCP separately because the organization and authentication are machine-local:

```powershell
pwsh -File .\scripts\install-azure-devops-mcp.ps1 -Organization confitecDevOps -WhatIf
pwsh -File .\scripts\install-azure-devops-mcp.ps1 -Organization confitecDevOps
```

The script merges, rather than replaces, Codex, Cursor, and Antigravity MCP configuration. It enables only `core`, `work`, `work-items`, and `repositories`; authentication remains interactive on first use.

## Starting a project

1. Record the default executor if useful.
2. Add root `AGENTS.md` for cross-executor project conventions.
3. Keep requirements, specs, architecture, decisions, and tasks as reviewed Markdown.
4. Run the chosen executor, implement against the active spec, test, review, and update durable documentation.

## Updating or installing elsewhere

```powershell
git pull --ff-only
pwsh -File .\scripts\materialize.ps1
pwsh -File .\scripts\verify.ps1
pwsh -File .\scripts\install.ps1 -WhatIf
pwsh -File .\scripts\install.ps1
```

On another computer, clone this private repository and run the same sequence. Paths derive from the user profile unless overridden.

## Export, recovery, and removal

`scripts/export.ps1` exports only allowlisted Codex memory, roles, and shared skills. Generated instructions must be changed at their Markdown sources and rematerialized.

There is no automatic uninstall yet. Managed targets are individually backed up under each runtime's `portable-backups/<timestamp>/`. Remove only documented managed paths and restore a selected backup if needed; never delete an entire runtime directory.

## Extending

Add a skill once under `skills/<name>/SKILL.md`, register it in `portable-manifest.json`, verify, and reinstall. A new executor needs only an adapter manifest, minimal native projections, installer wiring, and an isolated smoke test.

## Known limitations

- Cursor account-synced rules and Cloud Agent skill sync are UI/account state and are not managed.
- MCP servers, credentials, runtime binaries, and model availability remain external.
- Hooks are intentionally project-specific and opt-in.
- Copy-based installation requires rerunning the installer after updates.
- Automatic uninstall is not implemented.

## Verification

```powershell
pwsh -File .\scripts\verify.ps1
pwsh -File .\tests\test-portability.ps1
pwsh -File .\tests\test-cursor-adapter.ps1
pwsh -File .\tests\test-card-branch.ps1
pwsh -File .\tests\test-azure-devops-mcp.ps1
pwsh -File .\tests\test-antigravity-adapter.ps1
pwsh -File .\tests\test-ollama-adapter.ps1
pwsh -File .\tests\test-execution-boundary.ps1
```
