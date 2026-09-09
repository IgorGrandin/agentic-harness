# Provider-agnostic agentic platform V2

Status: implemented

## Outcome

Generalize the existing Codex harness into a Markdown-first agentic platform with explicit boundaries between core policy, profiles, runtime adapters, models, skills, tools/MCP, and memory. Codex remains the software-engineering regression baseline, but the harness installation is global and applies every supported adapter.

## Observed V1 baseline

- `global/AGENTS.md` combines universal operating policy with software and Codex behavior.
- `portable-manifest.json` allowlists one Codex-oriented installation surface.
- `scripts/install.ps1`, `scripts/export.ps1`, and `scripts/verify.ps1` operate safely on explicit paths.
- Codex materializes to `~/.codex/AGENTS.md`, `~/.codex/memory-bank/`, `~/.codex/agents/`, `~/.agents/skills/`, and selected `[agents]` settings.
- The existing memory bank already uses index-first progressive disclosure and must not be rewritten.
- Baseline verification and portability tests passed before V2 edits.

## Classification map

| Boundary | Existing content | V2 destination |
|---|---|---|
| Universal | precedence, progressive disclosure, durable memory, simplicity, evidence, permissions, security | `core/policies/` |
| Coder | SDD, coding roles, Git/worktrees, engineering verification and specialist skills | `profiles/coder/` |
| Codex | `.codex` paths, agent TOML, `[agents]` merge, shared skill installation | `adapters/codex/` plus compatible `global/` materialization |
| Other runtimes | no current implementation | minimal Antigravity and Ollama adapters |
| Capabilities | implicit in runtime/tool configuration | shared `mcp/registry.json`, declared by profiles |
| Memory domains | one sound global bank | retain it and document domain ownership without cloning it |

## Architecture decision

Use composable Markdown source documents and thin adapter manifests. Checked-in runtime instruction files are generated materializations and are verified against their sources. Keep the existing `global/` Codex paths as compatibility outputs instead of moving consumers in one step.

The installer deploys the complete declarative harness to `~/.agentic-harness/` and applies every supported adapter on every run. Codex materializes to its existing paths. Antigravity always receives Assistant, Knowledge, and Home. The Ollama adapter and Modelfiles are always materialized, while the runtime binary, model weights, and `ollama create` remain external machine-local operations.

Rejected alternatives:

- Rename or replace `global/` immediately: rejected because it expands the Codex regression surface.
- Keep Codex as the default-only adapter: rejected because it makes the global harness behave like a Codex installer.
- Keep Knowledge and Home as optional Antigravity composition flags: rejected because they are permanent platform domains, not add-ons.
- Require every runtime binary during harness installation: rejected because one absent optional runtime would break otherwise valid adapters.
- Introduce an agent framework or graph runtime: rejected because no acceptance criterion requires executable orchestration.
- Duplicate complete policies for each runtime: rejected because it creates drift and violates the Core/Profile/Adapter separation.

## Phases

1. Audit and baseline verification.
2. Extract universal policies.
3. Create the executor-agnostic Coder Profile and runtime adapters; prove compatibility.
4. Create the Assistant Profile and documented Antigravity Adapter using current official paths; always compose Knowledge and Home.
5. Always install the Ollama adapter and Qwen 3.5 9B Modelfiles without installing the runtime or weights.
6. Add Knowledge/Home policy scaffolding and shared capability registry.
7. Verify materialization, allowlists, secrets boundary, global installation, Antigravity smoke contract, and versioned Ollama configuration.

## Acceptance criteria

The numbered acceptance criteria and non-goals in the user request are authoritative. Verification maps to them through the final test report and the following invariants:

- Default `install.ps1` installs the whole harness and applies Codex and Antigravity plus the versioned Ollama adapter.
- `export.ps1` never exports outside the explicit Codex allowlist.
- Runtime binaries, credentials, external integrations, Ollama weights, and local model creation remain external.
- Assistant, Knowledge, and Home are permanent profiles; their external integrations remain incremental.
- Runtime adapters distinguish the complete profile inventory from profiles active in that runtime.
- Codex knows the complete catalog while activating only Software; Antigravity knows the complete catalog while activating Assistant, Knowledge, and Home.
- Antigravity distinguishes `DECLARED`, `ACTIVE`, `CONNECTED`, and `PLANNED` state and does not present planned integrations as operational facts.
- Assistant routing classes do not imply fixed nominal model defaults, and Antigravity-to-Ollama fallback is not automatic in V2.
- Core policy contains no Sol/Luna/Terra routing.
- Knowledge changes require human review; bulk mutation is never automatic.
- Home Assistant is the target source of truth; Alexa and Smart Life/Tuya remain interfaces or bridges.
- No credentials, runtime state, model weights, personal sensitive data, or production secrets enter the repository.

## Verification strategy

- Run the repository verifier and all PowerShell tests.
- Compare generated adapter outputs to their declared sources.
- Exercise the global install plus legacy Codex export path in isolated homes.
- Exercise full-harness dry-run and Antigravity install behavior in isolated homes.
- Validate the Ollama base model and context parameters without requiring Ollama to be installed.
- Inspect the final Git diff and forbidden-path scan.
