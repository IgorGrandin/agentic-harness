# Agentic harness

Private, portable source of truth for a provider- and runtime-agnostic agentic harness. The local checkout is named `agentic-harness`; Codex is one runtime adapter and remains the software-engineering regression baseline.

One installation deploys the complete declarative harness to `~/.agentic-harness/` and always applies every supported adapter. Codex receives the Software Engineering Profile with the existing Sol/Luna/Terra routing. Antigravity receives Assistant, Knowledge, and Home together. The versioned Ollama adapter is always installed without making the Ollama binary or model weights mandatory.

## Architecture

```text
                           AGENTIC CORE
              context, memory, evidence, permissions
                                  |
                 +----------------+----------------+
                 |                |                |
             PROFILES         CAPABILITIES       MEMORY
       software / assistant   shared MCP/tool    domain-owned
        knowledge / home         registry         Markdown
                 |
              ADAPTERS
       codex / antigravity / ollama
                 |
              RUNTIMES
       Codex / Antigravity / Ollama
                 |
               MODELS
    Sol-Luna-Terra / cloud pools / Qwen 3.5 9B
```

These boundaries are deliberately distinct:

- **Core**: universal operating policy with no provider or model routing.
- **Profile**: behavior for a domain such as software, personal assistance, knowledge, or home.
- **Adapter**: thin translation/materialization into a runtime's supported files and paths.
- **Runtime**: the host that executes the agent.
- **Model**: capability selected by routing within a runtime.
- **Skill**: selectively loaded task procedure; discovery is not automatic loading.
- **Tool/MCP**: shared external capability, independently permissioned by profiles.
- **Memory**: durable domain-owned Markdown; conversation history is working memory.

## Repository layout

```text
core/policies/                 universal context, memory, lifecycle, evidence, security
profiles/software/             existing Codex software behavior
profiles/assistant/            small Windows/PowerShell personal-assistant profile
profiles/knowledge/            Obsidian policy and human-reviewed organization workflow
profiles/home/                 Home Assistant boundary and safety tiers
adapters/codex/                Codex manifest and compatibility rules
adapters/antigravity/          Antigravity 2.0 manifest, rules, and path documentation
adapters/ollama/               always-installed Qwen 3.5 9B Modelfiles
mcp/                           shared capability registry; no fake servers or secrets
memory/                        ownership rules for memory domains
global/                        checked-in Codex-compatible materialization and memory bank
skills/                        allowlisted software skills installed into ~/.agents/skills
scripts/                       materialize, install, export, and verify
tests/                         isolated portability and adapter smoke tests
```

## Install the harness

One command installs the complete harness and applies Codex, Antigravity, and the versioned Ollama configuration:

```powershell
pwsh -File .\scripts\install.ps1 -WhatIf
pwsh -File .\scripts\install.ps1
```

The former `-Runtime` and `-AntigravityProfile` parameters remain accepted temporarily so existing commands do not fail, but they no longer narrow installation. Every invocation applies the whole harness. Runtime binaries, credentials, MCP authentication, and Ollama weights remain external; the harness must not install or authenticate them implicitly.

## Codex compatibility

| Repository source | Local destination |
|---|---|
| complete declarative harness | `~/.agentic-harness/` |
| materialized `global/AGENTS.md` | `~/.codex/AGENTS.md` |
| `global/memory-bank/` | `~/.codex/memory-bank/` |
| `global/agents/*.toml` | `~/.codex/agents/` |
| allowlisted `skills/` | `~/.agents/skills/` |
| `config/agents.toml` | selected keys merged into `~/.codex/config.toml` |

The installer backs up every managed target and never replaces the complete `.codex`, `.gemini`, or `.agents` directory. It replaces only the explicitly allowlisted children of `~/.agentic-harness/`. Existing routing, roles, and software skills remain in the Software Profile instead of leaking into Core.

After editing Core, the Software Profile, or a runtime adapter, refresh checked-in runtime instructions:

```powershell
pwsh -File .\scripts\materialize.ps1
```

Verification rejects drift between source policy and materialized files.

## Antigravity adapter

Current Google Antigravity 2.0 documentation was checked on 2026-09-04. The adapter uses:

- Global rules: `~/.gemini/GEMINI.md`
- Global skills: `~/.gemini/config/skills/`
- Global MCP: `~/.gemini/config/mcp_config.json`
- Workspace rules/workflows/skills: `.agents/rules/`, `.agents/workflows/`, `.agents/skills/`

The single installation command always materializes Core plus Assistant, Knowledge, and Home into Antigravity's global rules:

```powershell
pwsh -File .\scripts\install.ps1
```

Applying this adapter means writing the global `GEMINI.md`; it does not install or launch Antigravity, copy software-only skills into it, create MCP servers, select cloud models, or write credentials. Configure MCP and authentication separately using the official runtime UI/configuration. Older official examples mention alternate skill paths; the documented adapter decision is in `adapters/antigravity/README.md`.

## Ollama/Qwen adapter

Every harness installation includes the local adapter and its two portable aliases over the official `qwen3.5:9b` model. Creating the models remains an explicit machine-local step because it may download large weights:

```powershell
ollama create qwen-local -f .\adapters\ollama\Modelfile.qwen-local
ollama create qwen-local-deep -f .\adapters\ollama\Modelfile.qwen-local-deep
```

- `qwen-local`: 8K context; target is the empirically validated full-GPU fast profile on the RTX 4060.
- `qwen-local-deep`: 16K context; mixed CPU/GPU placement is expected when the larger context no longer fits fully.

Ollama chooses actual layer placement from current VRAM. Verify it with `ollama ps`; the repository does not hardcode local GPU layer counts or model paths. Ollama, Qwen, and model weights are not required for installing or using the cloud runtime adapters.

Use local inference directly for private data, offline or batch work, simple transformations, or quota conservation. It is not a mandatory step before a cloud model.

## Knowledge and Home boundaries

Knowledge and Home are permanent parts of the harness and are always installed and composed for the Assistant runtime. Their external integrations remain incremental.

Obsidian is the personal-knowledge source of truth. The profile defines a human-reviewed workflow from inventory through verification; this version does not reorganize a vault or grant bulk-write authority.

Home Assistant is the target source of truth for residential automation. Smart Life/Tuya remains a bridge where needed, Alexa+ remains a voice/automation interface, and future agents should integrate primarily through Home Assistant MCP/API. This version installs nothing and migrates no devices or automations.

## Shared capabilities

`mcp/registry.json` declares capabilities independently from profiles. A profile may declare permission to use a capability without implying that a server is installed, authenticated, enabled, or loaded. No placeholder MCP implementation is included.

## Export and synchronization

Before using a second computer:

```powershell
git pull --ff-only
pwsh -File .\scripts\install.ps1
```

After deliberately changing allowlisted memory, roles, or software skills on a Codex machine:

```powershell
pwsh -File .\scripts\export.ps1
git diff --check
git diff
```

`global/AGENTS.md` is generated from Core + Software Profile + Codex Adapter. If the installed copy differs, export stops and asks for the source Markdown to be updated instead of reverse-engineering changes into the wrong boundary. The full `config.toml` is never exported.

## Verification

```powershell
pwsh -File .\scripts\verify.ps1
pwsh -File .\tests\test-portability.ps1
pwsh -File .\tests\test-antigravity-adapter.ps1
pwsh -File .\tests\test-ollama-adapter.ps1
```

The checks cover allowlisted structure, JSON and PowerShell syntax, materialization drift, Core isolation, profile/capability declarations, likely credentials, forbidden local state, Codex installation/config merge/export, Antigravity dry-run and composition, and Ollama model/context declarations.

## Security boundary

Keep this repository private. It must never contain authentication, tokens, API keys, sessions, SQLite runtime databases, logs, caches, attachments, browser state, model weights, machine identity, personal sensitive data, or production secrets. Adapters install only explicitly allowlisted files.

Repository visibility is not changed automatically. If the declared private policy ever conflicts with the actual GitHub visibility, resolve that as an explicit user decision before changing either the repository or this policy.

## Backups and recovery

Managed runtime files are backed up under the selected runtime home:

```text
~/.codex/portable-backups/<timestamp>/
~/.agentic-harness/portable-backups/<timestamp>/
~/.gemini/portable-backups/<timestamp>/
```

Only managed files and directories are touched. To recover, close the affected runtime and restore the desired files from the timestamped backup.
