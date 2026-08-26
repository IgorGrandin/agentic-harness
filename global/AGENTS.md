# Global operating agreements

## Scope and precedence

- Treat repository `AGENTS.md` files and explicit user instructions as the authority for project-specific behavior.
- Keep global guidance generic. Do not copy project architecture, commands, or transient task state here.

## SDD workflow

- For software work, use the `sdd-workflow` skill when the request is a bug, feature, discovery, refactor, or review.
- Route the request before expanding the workflow. Use the microtask fast lane when the work is explicit, local, low risk, and can be completed with at most one targeted inspection, one small edit, and one focused check.
- In the microtask fast lane, the user's request is the source of truth. Do not create a spec, plan, architecture comparison, subagent, or routing log unless new evidence invalidates the fast-lane classification.
- Markdown is the source of truth for specifications, decisions, and durable memory. Code and tests must trace back to the active specification or an explicit user request.
- Read only the memory-bank index first. Load linked memory files only when their routing notes match the current task.
- Prefer repository-local specifications under `docs/specs/` when the repository already uses that convention. Otherwise propose the smallest compatible location rather than imposing a new structure.
- Separate thinking from execution: ChatGPT may explore and draft a portable spec; Codex validates that spec against the real repository, resolves discrepancies, implements, and verifies.
- Do not build or require a formal workflow graph in V1. Keep stages and transitions explicit enough for later graph conversion.

## Simplicity gate

- Prefer existing extension points and the smallest change surface that satisfies the acceptance criteria.
- Before adding a service, document type, dependency, configuration or startup change, persistence layer, or new abstraction, identify which acceptance criterion requires it and why the existing path is insufficient.
- Do not add future-proofing, extensibility, or infrastructure for hypothetical requirements.
- When a simpler approach satisfies the same outcome, choose it unless repository evidence exposes a material risk.

## Model routing

- Default complex or repository-wide work to GPT-5.6 Sol with high reasoning.
- Keep the primary orchestrator and spec author on GPT-5.6 Sol, with reasoning proportional to the lane: low for microtasks, medium for clear bounded intake and synthesis, and high only for consequential work.
- Use GPT-5.6 Luna with medium reasoning as the default subagent worker for bounded, low-risk, independently verifiable work or read-only scouting.
- Raise Luna to max reasoning only when the activity remains narrow and low risk but needs unusually deep local reasoning. Escalate to Terra when complexity broadens beyond that lane.
- Do not equate sequential work with primary-agent work. For a bounded implementation larger than a microtask, spawn one Luna Medium worker and wait for it sequentially; lack of parallelism is not a reason for Sol to implement it.
- Sol may execute a microtask directly only while it remains within the fast-lane budget. Reclassify and delegate as soon as additional exploration, multiple meaningful edits, or broader verification is needed.
- Use GPT-5.6 Terra with high reasoning as the intermediate escalation tier when Luna is insufficient but Sol would be disproportionate.
- Escalate from Luna before implementation when scope, ambiguity, risk, or cross-cutting impact exceeds the Luna lane. Do not spend a full implementation attempt merely to prove escalation is needed.
- Follow `sdd-workflow/references/model-routing.md` for the detailed routing rubric.

## Reusable subagent roles

- Reusable roles are `scout`, `implementer`, `verifier`, `reviewer`, and `architect_escalation`.
- Choose the role from the activity and choose the model from complexity; do not bind a role to a technology, model, or skill.
- Load skills only when the delegated task matches their description. Name an explicitly required skill in the spawn task.
- The router decides the execution lane, reasoning effort, and whether work is parallel or sequential. Parallelism is never the default, while one sequential Luna Medium worker is the default for bounded work beyond a microtask.
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
- For microtasks, run only the smallest decisive check. For bounded delegated work, accept the worker's passing evidence and do not repeat the same check unless relevant files or test inputs changed afterward.
- Do not add a separate verifier or reviewer for low-risk work by default. Use them only when independence materially improves confidence.
- Run broad suites only when the change is cross-cutting, touches a contract, schema, security boundary, build system, or shared infrastructure, or when no narrower decisive check exists.
- Stop when the authorized acceptance criteria are met. Do not expand into unrelated cleanup, speculative hardening, or repeated confirmation.
- Surface conflicts between a supplied spec and repository reality before making a materially different implementation choice.
- Keep plans and status concise; expand only where risk or user review benefits.
