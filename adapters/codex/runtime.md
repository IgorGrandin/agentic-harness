## Codex runtime adapter

- Use `~/.codex/memory-bank/INDEX.md` as the global memory index.
- Discover reusable role definitions from `~/.codex/agents/` and shared skills from `~/.agents/skills/`.
- Treat repository `AGENTS.md` files as the project-specific instruction layer.
- When a repository contains `.agentic-harness/executor.json`, treat it as the documented default for new Coder tasks; an explicit user choice of runtime takes precedence.
- Keep Codex routing configuration in the allowlisted `[agents]` fragment installed by this repository.

### Local project toolchains

- Use the runtime and package manager installed and configured by the user for the repository. Respect the repository's `packageManager`, lockfile, and documented commands; do not substitute a bundled runtime, an alternate runtime, or another package manager without explicit authorization.
- On Windows, non-interactive shells may not inherit the runtime-manager activation visible in the user's terminal. Resolve `nvm`, `node`, `npm`, and `npx` from the local user environment and reuse the already configured version before reporting the toolchain unavailable.
- Do not install, activate, or switch runtime versions implicitly. If the repository's local toolchain still cannot be used, report the limitation instead of falling back to an alternate runtime.

### Runtime-specific routing

- Treat root context as premium. The orchestrator is a role, not a synonym for Sol. Select the root model for the work; an explicit user model choice always wins.
- Prefer GPT-5.6 Luna Medium as root for clear procedural or recurring workflows, implementation against an authoritative spec or manifest, and `/execute`. The root remains a thin operational control plane for intake, decomposition, routing, synthesis, and acceptance.
- The harness explicitly authorizes and instructs the primary Codex orchestrator to decide automatically whether to delegate each eligible activity; the user does not need to request subagents in every task or skill invocation.
- Apply that decision after decomposing the work by responsibility. Prefer bounded Luna scouts, implementers, verifiers, or reviewers when separate backend, frontend, infrastructure, test, or investigation surfaces can be isolated and the expected token, context, or latency savings exceed handoff and synthesis cost.
- Keep direct execution for microtasks and tightly coupled work whose handoff would cost more than it saves. A skill invocation does not disable delegation unless the skill explicitly requires direct execution or forbids subagents.
- Do not load a non-trivial project-local or execution-oriented skill into the root merely because it was invoked. Prefer a Luna scout with `fork_turns: "none"` to read the authoritative source and return a compact Skill Execution Capsule; control-plane skills needed for routing or specification may be read directly by Sol.
- Once a stage is delegated, do not shadow-execute its investigation, skill reading, checks, or process polling in the root. Resume that surface only for failure, escalation, conflicting evidence, or a material decision.
- The worker that starts a long-running build, test, gate, or similar process owns its waiting and polling through completion and returns a compact completion packet rather than raw logs.
- Codex may use its configured Sol, Luna, and Terra routes. These model names belong to this adapter, never to the Coder profile.
- Use Luna Max when the authorized problem remains narrow but needs substantially deeper local reasoning or difficult bounded investigation. Use Terra High when complexity broadens across files, components, or bounded surfaces without introducing a material product, architecture, security, data, or compatibility decision.
- Route material or consequential decisions to Sol as decision authority through `architect_escalation`; do not make Sol the permanent mechanical executor. Unless the user explicitly overrides the tier, every first Sol escalation MUST use Sol Low, including high-risk categories. Do not select Sol Medium or High prospectively from the task category alone.
- Sol Medium requires an evidence-backed insufficiency packet from Sol Low identifying the unresolved decision, missing synthesis or ambiguity, and why another Low pass or more evidence is insufficient. Sol High likewise requires an insufficiency packet from Sol Medium identifying the exceptional remaining risk or ambiguity. Availability, perceived difficulty, context size, or a free budget never justifies skipping a rung.
- MUST escalate to Sol for conflict between authoritative instructions and repository reality, product or architecture decisions, non-mechanical auth/security/permission choices, ambiguous or consequential data integrity/migration decisions, important public API or compatibility changes, scope/release expansion, materially contradictory evidence, material reviewer findings without an obvious accepted correction, or required human authorization.
- MUST NOT escalate merely to read or edit files under a clear spec, change config or Markdown, run tests/builds, wait for a process, inspect Git, generate mechanical metadata, apply a decision already made, or implement an accepted mechanical correction.
- Treat the configured default subagent model as a fallback, not enforcement. Every Codex spawn must explicitly set `model` and `reasoning_effort` from the routing rubric.
- A spawn that selects a model different from the primary agent must use `fork_turns: "none"` or a positive limited turn count and pass the bounded context in its task. Never use `fork_turns: "all"` for Luna or Terra because a full-history fork inherits the primary Sol model.
- Use a Sol subagent only for consequential judgment that cannot remain with the primary orchestrator or a lower tier. Record the concrete ambiguity, risk, or cross-domain decision that required Sol; availability or a free concurrency slot is not sufficient.
- Escalate before implementation when the selected lane is clearly insufficient; do not require a failed attempt.
- Follow `sdd-workflow/references/model-routing.md` for the detailed rubric.
- Run at most three subagents concurrently while the installed Codex configuration retains that limit.
- Use `~/.agentic-harness/bin/agentic-run.ps1` for long deterministic commands and `~/.agentic-harness/bin/agentic-finalize.ps1` for manifest-authorized mechanical finalization. Do not repeatedly call `write_stdin` or status tools to ask whether a process has finished when the blocking runner is available.

### Runtime activation and current state

- This Codex adapter activates Coder. Assistant, Knowledge, and Home remain known platform profiles but are not activated by this adapter.
- The shared/global Markdown memory bank is `CONNECTED` through `~/.codex/memory-bank/` after installation.
- Software project memory is `CONNECTED` only when the current repository provides the relevant Markdown sources and they are loaded for the task.
- The Assistant durable-memory source, Obsidian integration, Home Assistant integration, and automatic Codex-to-Ollama routing remain `PLANNED` unless current evidence proves otherwise.

### Model names and routing

- Sol, Luna, and Terra are `CONFIGURED` names in this Codex adapter's routing policy.
- Do not claim that a configured model is `AVAILABLE` or `SELECTED` without current runtime evidence.
- Qwen through Ollama is a declared local route for appropriate work, not an automatic Codex fallback in this V2.
