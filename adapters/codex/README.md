# Codex adapter

This is the software-engineering regression-baseline adapter. It materializes Core plus the Software Engineering Profile into `global/AGENTS.md`, while preserving the existing memory, agent, shared-skill, and `[agents]` installation paths.

Codex receives the complete platform catalog but activates only Software. Its runtime rules distinguish declared, active, connected, configured, available, selected, and planned state; Qwen/Ollama is not an automatic fallback.

Run `scripts/materialize.ps1 -Runtime Codex` after changing a contributing Core, Software Profile, or Codex adapter source. Verification rejects drift between the sources and `global/AGENTS.md`.
