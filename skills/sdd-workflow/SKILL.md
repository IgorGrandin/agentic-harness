---
name: sdd-workflow
description: Run specification-driven software work for bugs, features, discovery, refactors, and reviews. Use when Codex should validate intent against a repository, maintain a Markdown source of truth, implement or analyze with proportionate verification, and preserve a handoff trail. Do not use for casual conceptual brainstorming with no repository work.
---

# SDD workflow

Turn the request and repository evidence into the smallest reviewable Markdown source of truth, then execute only the stages the request authorizes.

## Start cheaply

1. Read applicable `AGENTS.md` files and existing project docs.
2. Classify the task as bug, feature, discovery, refactor, or review.
3. Read only the matching workflow reference:
   - Bug: [references/bug.md](references/bug.md)
   - Feature: [references/feature.md](references/feature.md)
   - Discovery: [references/discovery.md](references/discovery.md)
   - Refactor: [references/refactor.md](references/refactor.md)
   - Review: [references/review.md](references/review.md)
4. For model selection or delegation, read [references/model-routing.md](references/model-routing.md).
5. When using subagents, also read [references/subagent-orchestration.md](references/subagent-orchestration.md).
6. If the input is a ChatGPT-produced spec, also read [references/spec-contract.md](references/spec-contract.md).
7. Load a specialist skill only when its decision surface applies:
   - Repository-grounded design uncertainty or a material architectural decision: `repo-aware-architecture`.
   - A defect whose cause is not established: `systematic-debugging`.
   - Creation or substantial redesign of an interface: `frontend-design`.
   - Explicit or materially warranted usability/accessibility review: `ui-ux-quality-review`.
   - A consumed API, schema, event, webhook, or DTO-boundary change: `api-contract-review`.
   - A schema migration, backfill, constraint, index, or risky persistence change: `database-change-safety`.

Do not load every reference. Avoid creating a spec file for a trivial, self-contained change when the request itself is already an adequate source of truth and no durable decision is needed.

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
- Verification must address the acceptance criteria and regression surface, not merely show that a command ran.
- Update durable memory only under the global memory write policy.

## Handoff

Conclude with: outcome, changed artifacts, verification evidence, unresolved risks, and the next meaningful decision if one remains.
