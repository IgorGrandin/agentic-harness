## Codex runtime adapter

Use `~/.codex/memory-bank/`, `~/.agents/skills/`, repository `AGENTS.md`, and
`~/.codex/agents/`; `.agentic-harness/executor.json` is the default unless the
user explicitly selects another runtime. Keep routing in the allowlisted
`[agents]` fragment. The shared memory is `CONNECTED` through `~/.codex/memory-bank/`.

The orchestrator is a role, not a synonym for Sol; it is not a model identity. Treat root context as premium:
Prefer GPT-5.6 Luna Medium as root for clear procedural work and `/execute`; keep every root
thin. The host selects the root. Native agents perform semantic work while
`agentic-run.ps1` and `agentic-finalize.ps1` own deterministic waiting,
receipts, and safety. do not shadow-execute or repeatedly call `write_stdin`.

Delegate only when context isolation or parallelism has material benefit. Use a Skill Execution Capsule for bounded delegation. Every Codex spawn must explicitly set `model` and `reasoning_effort`, use
`fork_turns: "none"` for bounded context. Never use `fork_turns: "all"` for Luna or Terra. Run at most three subagents concurrently; the
worker owns its waiting and polling through completion.

Use Luna Max for narrow difficult investigation and Terra High for broader
bounded surfaces. Consequential decisions go to Sol as architect escalation:
every first Sol escalation MUST use Sol Low; Sol Medium requires an evidence-backed insufficiency packet from Sol Low; Sol High requires one from Sol Medium. MUST NOT skip rungs. Use a Sol subagent only for consequential judgment, never as permanent mechanical executor.

The four permanent profiles are declared by the harness. This Codex adapter activates Coder;
Assistant, Knowledge, and Home remain known platform profiles but are not activated.
Sol, Luna, and Terra are `CONFIGURED` names, not claims of availability or
selection. Qwen through Ollama is a declared route, not an automatic Codex fallback.
