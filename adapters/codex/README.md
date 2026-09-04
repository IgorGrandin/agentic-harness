# Codex adapter

This is the default and regression-baseline adapter. It materializes Core plus the Software Engineering Profile into `global/AGENTS.md`, while preserving the existing memory, agent, shared-skill, and `[agents]` installation paths.

Run `scripts/materialize.ps1 -Runtime Codex` after changing a contributing Core, Software Profile, or Codex adapter source. Verification rejects drift between the sources and `global/AGENTS.md`.
