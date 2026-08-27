# Global operating agreements

## Scope and precedence

- Treat repository `AGENTS.md` files and explicit user instructions as the authority for project-specific behavior.
- Keep global guidance generic. Do not copy project architecture, commands, or transient task state here.

## SDD workflow

- For software work, use the `sdd-workflow` skill when the request is a bug, feature, discovery, refactor, or review.
- Route before expanding the workflow. Explicit, local, low-risk work uses the skill's fast lane with no spec, plan, subagent, or routing log.
- Markdown is the source of truth for specifications, decisions, and durable memory. Code and tests must trace back to the active specification or an explicit user request.
- Read only the memory-bank index first. Load linked memory files only when their routing notes match the current task.
- Separate thinking from execution: ChatGPT may explore and draft a portable spec; Codex validates that spec against the real repository, resolves discrepancies, implements, and verifies.

## Simplicity gate

- Prefer existing extension points and the smallest change surface that satisfies the acceptance criteria.
- Before adding a service, document type, dependency, configuration or startup change, persistence layer, or new abstraction, identify which acceptance criterion requires it and why the existing path is insufficient.
- Do not add future-proofing, extensibility, or infrastructure for hypothetical requirements.
- When a simpler approach satisfies the same outcome, choose it unless repository evidence exposes a material risk.

## Model routing

- Keep orchestration and specification on GPT-5.6 Sol with proportional reasoning: low for simple work, medium for bounded synthesis, and high only for consequential work.
- Delegate to Luna Medium only when its cheaper execution or context isolation is expected to outweigh spawn and synthesis overhead. Use Luna Max for narrow deep reasoning, Terra High for broader bounded complexity, and Sol High for consequential judgment.
- Escalate before implementation when the selected lane is clearly insufficient; do not require a failed attempt.
- Follow `sdd-workflow/references/model-routing.md` for the detailed routing rubric.

## Reusable subagent roles

- Reusable roles are `scout`, `implementer`, `verifier`, `reviewer`, and `architect_escalation`.
- Choose the role from the activity and choose the model from complexity; do not bind a role to a technology, model, or skill.
- Load skills only when the delegated task matches their description. Name an explicitly required skill in the spawn task.
- Delegation and parallelism require a material net gain; dependent work remains sequential.
- Prefer one writer at a time. If multiple agents must edit concurrently, isolate each writer in its own worktree and assign non-overlapping ownership before spawning.
- Run at most three subagents concurrently during V1.
- Log only escalations, parallel execution, or non-obvious routing decisions using the compact format in `sdd-workflow/references/subagent-orchestration.md`.

## Durable memory

- Memory bank index: `~/.codex/memory-bank/INDEX.md`.
- Write durable memory only when the user asks, when a stable preference is explicitly established, or when a reusable lesson is confirmed by evidence.
- Never store secrets, credentials, personal sensitive data, raw logs, or speculative conclusions.
- Prefer updating an existing fact over appending duplicates. Include date and provenance for decisions or lessons.
- Repository-specific facts belong in repository documentation or local `AGENTS.md`, not the global memory bank.

## Execution discipline

- For diagnosis or review, inspect and report; do not implement unless requested.
- For requested changes, make scoped edits and run proportionate validation.
- Run the smallest decisive check. Accept a worker's passing evidence unless relevant files or inputs changed afterward.
- Do not add a separate verifier or reviewer for low-risk work by default. Use them only when independence materially improves confidence.
- Run broad suites only when the change is cross-cutting, touches a contract, schema, security boundary, build system, or shared infrastructure, or when no narrower decisive check exists.
- Stop when the authorized acceptance criteria are met. Do not expand into unrelated cleanup, speculative hardening, or repeated confirmation.
