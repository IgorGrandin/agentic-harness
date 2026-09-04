# Antigravity adapter

This always-applied adapter materializes Core plus Assistant, Knowledge, and Home into the current Antigravity global rule format. The profiles are permanent harness boundaries even while their Obsidian and Home Assistant integrations are implemented incrementally.

## Confirmed Antigravity 2.0 paths

Checked against current Google documentation on 2026-09-04:

- Global rule: `~/.gemini/GEMINI.md`
- Global skills: `~/.gemini/config/skills/`
- Global MCP configuration: `~/.gemini/config/mcp_config.json`
- Workspace rules: `<workspace>/.agents/rules/`
- Workspace workflows: `<workspace>/.agents/workflows/`
- Workspace skills: `<workspace>/.agents/skills/`

Sources:

- https://codelabs.developers.google.com/getting-started-google-antigravity
- https://codelabs.developers.google.com/getting-started-agy-ide
- https://developers.google.com/workspace/guides/configure-mcp-servers

Some older official labs mention other Antigravity skill paths. This adapter follows the consolidated Antigravity 2.0 path above and records the discrepancy rather than copying to every historical location.

## Global installation

```powershell
pwsh -File .\scripts\install.ps1
```

For Antigravity, the installer writes only `GEMINI.md`. It does not install or launch the runtime, invent MCP servers, choose models, or install credentials. Configure and authenticate MCP servers separately in Antigravity, then allow only the tools required by each project.
