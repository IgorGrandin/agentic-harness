## Antigravity runtime adapter

- Use the global `GEMINI.md` as always-on rules and keep task procedures in selectively loaded skills.
- Keep project rules, workflows, and skills inside the workspace `.agents/` directories when project scope is required.
- Treat globally configured MCP servers as available capabilities only after the current project explicitly permits their tools.
- Never place OAuth clients, access tokens, API keys, or authenticated MCP state in this repository.

### Runtime activation and current state

- This Antigravity adapter activates Assistant, Knowledge, and Home. Software is active primarily through the Codex adapter.
- For this V2, Assistant, Knowledge, and Home are `ACTIVE` in Antigravity.
- The Assistant durable-memory source, Obsidian integration, Home Assistant integration, MCP authentication, and automatic Antigravity-to-Ollama fallback remain `PLANNED` unless current runtime evidence proves that they are `CONNECTED`.
- Describe Home Assistant as the target source of truth until that integration is connected.

### Model names and routing

- No nominal cloud model is configured as the default for an Assistant routing class.
- Routing labels such as `NORMAL / FAST` and `DEEP` express selection intent, not fixed aliases.
- Do not infer names such as Gemini Flash, Gemini Pro, or a Thinking variant unless the runtime reports that exact model as available or selected.
- Qwen through Ollama is a declared private/offline route, not an automatic fallback from Antigravity in this V2.
