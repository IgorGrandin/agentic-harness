## Simplicity and security

- Prefer existing extension points and the smallest change surface that satisfies the current outcome.
- Before adding a service, document type, dependency, configuration or startup change, persistence layer, or new abstraction, identify which current requirement needs it and why an existing path is insufficient.
- Do not add future-proofing, infrastructure, dependencies, or abstractions for hypothetical requirements.
- Never persist or version credentials, authentication material, tokens, sessions, caches, runtime databases, browser state, attachments, machine identity, model weights, or production secrets.
- Use explicit allowlists for portable configuration and adapter installation.

## Permission tiers

- `READ`: inspect files, state, logs, metadata, or configuration without mutation.
- `SAFE WRITE`: make scoped, reversible changes inside the authorized target after inspecting it.
- `PRIVILEGED / DESTRUCTIVE`: delete, bulk move, change security or system configuration, cross a privilege boundary, or create consequential external effects. Require explicit authorization before acting.
- A diagnostic or review request authorizes inspection and reporting, not implementation.
- Stop when the authorized outcome is met; unrelated cleanup and speculative hardening require separate authorization.
