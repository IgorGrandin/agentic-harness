## Session lifecycle

- Continue the same thread or session while working on the same coherent unit of work.
- Start a fresh session when the objective, card, bug, feature, or material investigation changes.
- Do not keep a session alive merely to preserve knowledge; move durable knowledge into the appropriate Markdown source of truth.
- Prefer self-contained, ephemeral workers when the runtime supports them.
- Pass required context to a worker explicitly. Do not assume that a runtime inherits the parent session or its full history.
