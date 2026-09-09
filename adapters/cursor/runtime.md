## Cursor runtime adapter

- Use `~/.cursor/memory-bank/INDEX.md` as the global memory index.
- Discover shared skills from `~/.agents/skills/` and Cursor role projections from `~/.cursor/agents/`.
- Treat repository `AGENTS.md` and `.cursor/rules/*.mdc` as project-specific layers with higher specificity.
- When a repository contains `.agentic-harness/executor.json`, treat it as the documented default for new Coder tasks; an explicit user choice of runtime takes precedence.
- Keep MCP credentials and server activation in user- or project-managed `mcp.json`; the harness only declares capabilities.

### Runtime activation and current state

- This Cursor adapter activates Coder and is its default executor.
- The shared Markdown memory bank is `CONNECTED` through `~/.cursor/memory-bank/` after installation.
- Project context is `CONNECTED` only when the current repository supplies and loads its Markdown specifications, decisions, or architecture.
- A selected executor is an operational choice, not a model binding. Do not infer a model from the Coder profile.

### Hooks and lifecycle

- Cursor hooks are opt-in per project. Do not install global format, test, or blocking hooks because repositories use different commands and trust boundaries.
- Prefer a small project `.cursor/hooks.json` only when its commands already exist and are fast, deterministic, and documented.
- Useful events include `sessionStart` for bounded context, `afterFileEdit` for an existing formatter, and `stop` for a focused verification command.
