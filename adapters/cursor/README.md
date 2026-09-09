# Cursor adapter

Cursor consumes a generated global `.mdc` rule, shared skills from `~/.agents/skills`, copied Markdown memory, and generated native subagent files. The repository remains the source of truth.

The installer deliberately uses copies instead of Windows symbolic links or junctions. Copies work without Developer Mode or elevated link privileges and make installation predictable on additional computers. Re-run the installer after pulling changes.

Global Cursor user rules configured in the UI are not modified. MCP configuration and hooks are also left untouched because they can contain credentials or repository-specific commands.

Project rules belong in `.cursor/rules/`; plain `AGENTS.md` is also supported by Cursor and is appropriate when the same project instruction should be read by multiple executors.
