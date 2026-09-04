# Platform profile catalog and operational state

The harness declares four permanent profiles:

- Software: software engineering, active primarily through Codex.
- Assistant: general personal assistance, active primarily through Antigravity.
- Knowledge: Markdown-first second brain with Obsidian as its source-of-truth boundary, composed with Assistant.
- Home: residential automation with Home Assistant as its target source-of-truth boundary, composed with Assistant.

When asked for the platform inventory, name all four profiles and distinguish profiles declared by the harness from profiles active in the current runtime. Knowing that a profile exists does not activate its behavior, load its skills, grant access to capabilities, or connect an external service.

Use these operational-state terms precisely:

- `DECLARED`: present in the versioned harness.
- `ACTIVE`: included in the current runtime instructions.
- `CONNECTED`: an external tool, memory source, runtime, or service is configured and its availability has been verified.
- `PLANNED`: designed but not operationally connected.

For model claims, also distinguish `CONFIGURED` from `AVAILABLE` and `SELECTED`. A model named in routing policy is not necessarily available in the current runtime or selected for the current task. Never present declared architecture, routing intent, or planned integration as observed operational state.
