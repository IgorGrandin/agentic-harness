---
name: sdd-workflow
description: Run specification-driven software work for bugs, features, discovery, refactors, and reviews. Use when Codex should validate intent against a repository, maintain a Markdown source of truth, implement or analyze with proportionate verification, and preserve a handoff trail. Do not use for casual conceptual brainstorming with no repository work.
---

# SDD workflow

Turn the request and repository evidence into the smallest reviewable Markdown source of truth, then execute only the stages the request authorizes.

## Start cheaply

1. Read applicable `AGENTS.md` files. Inspect only the project docs needed to understand the requested surface.
2. Choose a processing lane before expanding the workflow:
   - **Microtask fast lane:** explicit, local, low-risk work that needs at most one targeted inspection, one small edit, and one focused check. Use the request as the source of truth; do not create a spec, plan, architecture comparison, subagent, or routing log.
   - **Bounded lane:** clear, low-risk work larger than a microtask. Delegate execution to one sequential Luna Medium worker using [references/subagent-orchestration.md](references/subagent-orchestration.md).
   - **Consequential lane:** ambiguity, cross-cutting impact, costly verification, or material risk. Use the full lifecycle and the routing rubric.
3. If evidence exceeds the current lane, reclassify before further implementation. Do not finish a larger task under a cheaper lane merely because execution has started.
4. Outside the microtask fast lane, classify the task as bug, feature, discovery, refactor, or review and read only the matching workflow reference:
   - Bug: [references/bug.md](references/bug.md)
   - Feature: [references/feature.md](references/feature.md)
   - Discovery: [references/discovery.md](references/discovery.md)
   - Refactor: [references/refactor.md](references/refactor.md)
   - Review: [references/review.md](references/review.md)
5. For model selection or delegation, read [references/model-routing.md](references/model-routing.md).
6. When using subagents, also read [references/subagent-orchestration.md](references/subagent-orchestration.md).
7. If the input is a ChatGPT-produced spec, also read [references/spec-contract.md](references/spec-contract.md).
8. Load a specialist skill only when its decision surface applies:
   - Repository-grounded design uncertainty or a material architectural decision: `repo-aware-architecture`.
   - A defect whose cause is not established: `systematic-debugging`.
   - Creation or substantial redesign of an interface: `frontend-design`.
   - Explicit or materially warranted usability/accessibility review: `ui-ux-quality-review`.
   - A consumed API, schema, event, webhook, or DTO-boundary change: `api-contract-review`.
   - A schema migration, backfill, constraint, index, or risky persistence change: `database-change-safety`.

Do not load every reference. The microtask fast lane must remain one pass: inspect, edit, check, and stop. If more work is required, leave the lane rather than stretching its budget.

Specialist skills refine a stage; they do not replace this lifecycle or run automatically merely because a file belongs to their broad technical domain. When several apply, load them at the stage where their output is needed rather than all at intake.

## Shared lifecycle

Use these semantic stages; skip stages that do not apply:

`intake -> evidence -> specification -> decision -> execution -> verification -> handoff`

Each stage should expose a reviewable output or a clear transition condition. This is a workflow contract, not a formal graph implementation.

## Invariants

- Repository evidence outranks assumptions in an imported spec.
- Record material discrepancies as amendments; do not silently reinterpret acceptance criteria.
- Distinguish observed facts, hypotheses, decisions, and open questions.
- Preserve user authorization: discovery and review do not imply permission to edit.
- Keep artifacts concise and link to existing project documents instead of duplicating them.
- Prefer the smallest change surface that meets the acceptance criteria. New components or infrastructure require a concrete criterion and evidence that an existing extension point is insufficient.
- Treat unrequested future-proofing and hypothetical extensibility as out of scope.
- Verification must address the acceptance criteria and regression surface, not merely show that a command ran.
- Use the smallest decisive verification. Do not rerun a passing check unless relevant code or inputs changed afterward, and do not run a broad suite when a focused check decisively covers low-risk work.
- Do not add independent verifier or reviewer stages to low-risk work unless they provide material confidence beyond the implementer's evidence.
- Stop after the authorized acceptance criteria are satisfied; unrelated cleanup and speculative hardening require separate authorization.
- Update durable memory only under the global memory write policy.

## Handoff

Conclude with: outcome, changed artifacts, verification evidence, unresolved risks, and the next meaningful decision if one remains.
