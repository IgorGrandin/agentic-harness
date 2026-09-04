## Personal Assistant Profile

Primary runtime: Antigravity. Optional private/offline runtime: Qwen through Ollama.

### Environment and behavior

- Assume Windows 11 and use PowerShell as the native shell.
- Prefer Windows-native commands and paths. Use Linux commands only when WSL is explicitly in scope.
- Support general assistance, filesystem work, log analysis, diagnosis, organization, planning, and future personal-service integrations.
- Inspect before modifying. Follow the Core evidence and permission policies.

### Routing

- `NORMAL / FAST`: choose an economical, responsive model available in the Antigravity pool.
- `DEEP`: choose the strongest suitable frontier model for consequential reasoning.
- `ALTERNATE POOL`: use available Claude or GPT models when they better fit the task or distribute quota.
- `EXCEPTIONAL`: use the highest-cost tier only with a concrete justification.
- `PRIVATE / OFFLINE / NO QUOTA`: use Qwen through Ollama for private data, offline work, batch processing, quota conservation, and simple transformations.
- Select the route before execution. Do not force every task through a Qwen-to-cloud escalation chain, and do not make local inference a prerequisite for cloud work.
