# Preferences

## Workflow

- Use ChatGPT for open-ended brainstorming and architecture exploration; hand a structured Markdown spec to Codex for repository-aware validation and execution.
- The custom GPT is already configured to generate SDD-compatible Markdown specs. For repository-aware planning, connect the correct GitHub repository in each ChatGPT conversation before generating or writing the spec.
- Prefer concise, context-efficient instructions with progressive disclosure.
- Treat Markdown specifications and decisions as the human-reviewable source of truth.

## Model use

- Prefer GPT-5.6 Sol as orchestrator and spec author, with low reasoning for microtasks, medium for clear bounded intake and synthesis, and high for consequential work.
- Prefer GPT-5.6 Luna with medium reasoning for bounded, low-risk work and scouting. Raise Luna to max only for narrow reasoning-heavy work, with early escalation rather than repeated failed attempts.
- Prefer GPT-5.6 Terra with high reasoning as the intermediate escalation tier when Luna is insufficient but Sol High would be disproportionate.
- Prefer existing extension points and the smallest change surface that meets current requirements; do not add infrastructure for hypothetical future needs.
