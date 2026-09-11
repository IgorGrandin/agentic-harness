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

- Treat root context as premium. The primary Sol agent is a thin control plane for intake, decomposition, specification ownership, routing, consequential decisions, synthesis, and final acceptance; move noisy or mechanical execution out of the root when delegation has a material net gain.
- The harness explicitly authorizes and instructs the primary Codex orchestrator to decide automatically whether to delegate each eligible activity; the user does not need to request subagents in every task or skill invocation.
- Apply that decision after decomposing the work by responsibility. Prefer bounded Luna scouts, implementers, verifiers, or reviewers when separate backend, frontend, infrastructure, test, or investigation surfaces can be isolated and the expected token, context, or latency savings exceed handoff and synthesis cost.
- Keep direct execution for microtasks and tightly coupled work whose handoff would cost more than it saves. A skill invocation does not disable delegation unless the skill explicitly requires direct execution or forbids subagents.
- Do not load a non-trivial project-local or execution-oriented skill into the root merely because it was invoked. Prefer a Luna scout with `fork_turns: "none"` to read the authoritative source and return a compact Skill Execution Capsule; control-plane skills needed for routing or specification may be read directly by Sol.
- Once a stage is delegated, do not shadow-execute its investigation, skill reading, checks, or process polling in the root. Resume that surface only for failure, escalation, conflicting evidence, or a material decision.
- The worker that starts a long-running build, test, gate, or similar process owns its waiting and polling through completion and returns a compact completion packet rather than raw logs.
- Codex may use its configured Sol, Luna, and Terra routes. These model names belong to this adapter, never to the Coder profile.
- Keep orchestration and specification on GPT-5.6 Sol with proportional reasoning: low for simple work, medium for bounded synthesis, and high only for consequential work.
- Delegate to Luna Medium only when cheaper execution or context isolation is expected to outweigh spawn and synthesis overhead.
- Use Luna Max for narrow deep reasoning, Terra High for broader bounded complexity, and Sol High for consequential judgment.
- Treat the configured default subagent model as a fallback, not enforcement. Every Codex spawn must explicitly set `model` and `reasoning_effort` from the routing rubric.
- A spawn that selects a model different from the primary agent must use `fork_turns: "none"` or a positive limited turn count and pass the bounded context in its task. Never use `fork_turns: "all"` for Luna or Terra because a full-history fork inherits the primary Sol model.
- Use a Sol subagent only for consequential judgment that cannot remain with the primary orchestrator or a lower tier. Record the concrete ambiguity, risk, or cross-domain decision that required Sol; availability or a free concurrency slot is not sufficient.
- Escalate before implementation when the selected lane is clearly insufficient; do not require a failed attempt.
- Follow `sdd-workflow/references/model-routing.md` for the detailed rubric.
- Run at most three subagents concurrently while the installed Codex configuration retains that limit.

### Runtime activation and current state

- This Codex adapter activates Coder. Assistant, Knowledge, and Home remain known platform profiles but are not activated by this adapter.
- The shared/global Markdown memory bank is `CONNECTED` through `~/.codex/memory-bank/` after installation.
- Software project memory is `CONNECTED` only when the current repository provides the relevant Markdown sources and they are loaded for the task.
- The Assistant durable-memory source, Obsidian integration, Home Assistant integration, and automatic Codex-to-Ollama routing remain `PLANNED` unless current evidence proves otherwise.

### Model names and routing

- Sol, Luna, and Terra are `CONFIGURED` names in this Codex adapter's routing policy.
- Do not claim that a configured model is `AVAILABLE` or `SELECTED` without current runtime evidence.
- Qwen through Ollama is a declared local route for appropriate work, not an automatic Codex fallback in this V2.
