# Global operating agreements

## Scope and precedence

- Treat repository `AGENTS.md` files and explicit user instructions as the authority for project-specific behavior.
- Keep global guidance generic. Do not copy project architecture, commands, or transient task state here.

## SDD workflow

- For software work, use the `sdd-workflow` skill when the request is a bug, feature, discovery, refactor, or review.
- Markdown is the source of truth for specifications, decisions, and durable memory. Code and tests must trace back to the active specification or an explicit user request.
- Read only the memory-bank index first. Load linked memory files only when their routing notes match the current task.
- Prefer repository-local specifications under `docs/specs/` when the repository already uses that convention. Otherwise propose the smallest compatible location rather than imposing a new structure.
- Separate thinking from execution: ChatGPT may explore and draft a portable spec; Codex validates that spec against the real repository, resolves discrepancies, implements, and verifies.
- Do not build or require a formal workflow graph in V1. Keep stages and transitions explicit enough for later graph conversion.

## Model routing

- Default complex or repository-wide work to GPT-5.6 Sol with high reasoning.
- Keep the primary orchestrator and spec author on GPT-5.6 Sol with high reasoning.
- Use GPT-5.6 Luna with max reasoning as the default subagent worker for bounded, low-risk, independently verifiable work or read-only scouting.
- Use GPT-5.6 Terra with high reasoning as the intermediate escalation tier when Luna is insufficient but Sol would be disproportionate.
- Escalate from Luna before implementation when scope, ambiguity, risk, or cross-cutting impact exceeds the Luna lane. Do not spend a full implementation attempt merely to prove escalation is needed.
- Follow `sdd-workflow/references/model-routing.md` for the detailed routing rubric.

## Reusable subagent roles

- Reusable roles are `scout`, `implementer`, `verifier`, `reviewer`, and `architect_escalation`.
- Choose the role from the activity and choose the model from complexity; do not bind a role to a technology, model, or skill.
- Load skills only when the delegated task matches their description. Name an explicitly required skill in the spawn task.
- The router decides whether to delegate and whether work is parallel or sequential. Parallelism is never the default.
- Run tasks in parallel only when they are independent, have bounded inputs and outputs, and the expected latency or context-quality gain exceeds coordination overhead.
- Keep dependent stages sequential. An agent must not begin from an output another running agent has not produced.
- Prefer one writer at a time. If multiple agents must edit concurrently, isolate each writer in its own worktree and assign non-overlapping ownership before spawning.
- Run at most three subagents concurrently during V1.
- Record each routing or escalation decision in the compact format defined by `sdd-workflow/references/subagent-orchestration.md`.

## Durable memory

- Memory bank index: `~/.codex/memory-bank/INDEX.md`.
- Write durable memory only when the user asks, when a stable preference is explicitly established, or when a reusable lesson is confirmed by evidence.
- Never store secrets, credentials, personal sensitive data, raw logs, or speculative conclusions.
- Prefer updating an existing fact over appending duplicates. Include date and provenance for decisions or lessons.
- Repository-specific facts belong in repository documentation or local `AGENTS.md`, not the global memory bank.

## Execution discipline

- For diagnosis or review, inspect and report; do not implement unless requested.
- For requested changes, make scoped edits and run proportionate validation.
- Surface conflicts between a supplied spec and repository reality before making a materially different implementation choice.
- Keep plans and status concise; expand only where risk or user review benefits.
