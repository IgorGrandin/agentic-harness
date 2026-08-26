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

Amended: 2026-08-21, based on observed overengineering in a bounded feature and successful simplification after reducing reasoning effort and clarifying non-goals.

Decision: Scout, Implementer, Verifier, Reviewer, and Architect/Escalation are reusable activity roles. They do not encode a technology, fixed model, or fixed skill. The primary orchestrator stays in the Sol family with effort proportional to the task. Spawned agents default to Luna Medium, may rise to Luna Max for narrow reasoning-heavy work, and escalate to Terra High or Sol High when complexity warrants it.

Rationale: role describes responsibility, model describes required capability, and skill supplies task-specific procedure. Keeping these axes separate avoids an agent explosion and permits routing changes without rewriting role definitions.

## 2026-08-21 — Prefer the smallest sufficient change surface

Status: active

Decision: reuse existing extension points and choose the smallest change surface that satisfies current acceptance criteria. New components, abstractions, dependencies, persistence mechanisms, and configuration or startup changes require a present decision driver and evidence that the existing path is insufficient. Hypothetical future-proofing is out of scope unless explicitly requested.

Rationale: additional architecture is not inherently higher quality. Requiring a present need prevents speculative complexity, reduces token and verification cost, and keeps changes reversible.

## 2026-08-20 — Parallelism is router-controlled

Status: active

Decision: V1 runs at most three subagents concurrently. The router parallelizes only independent tasks with a material latency or context-isolation gain. Dependencies remain sequential. Concurrent writers require separate Git worktrees, non-overlapping ownership, and sequential integration.

Rationale: bounded concurrency supports early evaluation while avoiding speculative fan-out, shared-worktree conflicts, and unnecessary token use.

## 2026-08-21 — Version the portable global configuration privately

Status: active

Decision: `https://github.com/IgorGrandin/codex-global-config` is the private Git source of truth for the portable global Codex configuration. It contains the global `AGENTS.md`, Markdown memory bank, reusable subagent roles, user-authored skills, sanitized routing settings, and verified PowerShell install/export scripts. Authentication, sessions, caches, local databases, and machine identity remain local and must never be synchronized through this repository.

Rationale: an explicit, allowlisted private repository makes the global SDD setup reproducible across computers without copying sensitive or machine-specific Codex state.
