## Codex runtime adapter

- Use `~/.codex/memory-bank/INDEX.md` as the global memory index.
- Discover reusable role definitions from `~/.codex/agents/` and shared skills from `~/.agents/skills/`.
- Treat repository `AGENTS.md` files as the project-specific instruction layer.
- Keep Codex routing configuration in the allowlisted `[agents]` fragment installed by this repository.

### Runtime activation and current state

- This Codex adapter activates Software. Assistant, Knowledge, and Home remain known platform profiles but are not activated by this adapter.
- The shared/global Markdown memory bank is `CONNECTED` through `~/.codex/memory-bank/` after installation.
- Software project memory is `CONNECTED` only when the current repository provides the relevant Markdown sources and they are loaded for the task.
- The Assistant durable-memory source, Obsidian integration, Home Assistant integration, and automatic Codex-to-Ollama routing remain `PLANNED` unless current evidence proves otherwise.

### Model names and routing

- Sol, Luna, and Terra are `CONFIGURED` names in the Software Profile routing policy.
- Do not claim that a configured model is `AVAILABLE` or `SELECTED` without current runtime evidence.
- Qwen through Ollama is a declared local route for appropriate work, not an automatic Codex fallback in this V2.
