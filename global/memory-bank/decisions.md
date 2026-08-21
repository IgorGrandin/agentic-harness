# Cross-project decisions

## 2026-08-20 — SDD V1 is Markdown-first

Status: active

Decision: specifications, decisions, and durable memory use Markdown as their source of truth. V1 uses explicit workflow stages and transitions but no formal graph runtime.

Rationale: Markdown is portable, reviewable, repository-friendly, and cheap to load selectively. The stage model can later be converted into a graph without changing artifact semantics.

## 2026-08-20 — Separate repository-independent ideation from repository-grounded design

Status: active

Decision: ChatGPT/GPT handles open-ended ideation that does not require repository evidence and may produce a portable spec. When feature or architecture choices depend on the current system, Codex uses the global `repo-aware-architecture` skill to inspect the repository, compare trade-offs, record the decision, and return an SDD-ready spec. Codex validates any imported spec against repository reality before execution.

Rationale: repository-independent thinking can avoid agentic repository cost, while system design based on existing constraints requires direct access to code, tests, project instructions, and operational evidence.

## 2026-08-20 — Use the GitHub-connected custom GPT as an optional planning front door

Status: active

Decision: the user's custom GPT is configured to perform brainstorming and architecture work and produce SDD-compatible Markdown. When repository evidence is required, the user connects the correct GitHub repository for that conversation and the GPT writes the spec into that repository. Codex treats the resulting Markdown as an imported spec, validates only its material claims against the active checkout, records discrepancies as amendments, and avoids repeating completed brainstorming or design work.

Rationale: this preserves a compact, reviewable handoff between ChatGPT and Codex, reduces duplicated reasoning, and keeps the local repository and tests authoritative when the GitHub view or branch has drifted.

## 2026-08-20 — Subagent roles are independent from model and skill

Status: active

Decision: Scout, Implementer, Verifier, Reviewer, and Architect/Escalation are reusable activity roles. They do not encode a technology, fixed model, or fixed skill. The primary orchestrator uses Sol High; spawned agents default to Luna Max, with Terra High and Sol High selected explicitly when complexity warrants escalation.

Rationale: role describes responsibility, model describes required capability, and skill supplies task-specific procedure. Keeping these axes separate avoids an agent explosion and permits routing changes without rewriting role definitions.

## 2026-08-20 — Parallelism is router-controlled

Status: active

Decision: V1 runs at most three subagents concurrently. The router parallelizes only independent tasks with a material latency or context-isolation gain. Dependencies remain sequential. Concurrent writers require separate Git worktrees, non-overlapping ownership, and sequential integration.

Rationale: bounded concurrency supports early evaluation while avoiding speculative fan-out, shared-worktree conflicts, and unnecessary token use.
