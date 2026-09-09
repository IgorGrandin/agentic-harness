---
name: azure-devops-card-flow
description: Transforms Azure DevOps work items into repository-local execution specifications and coordinates ChatGPT clarification, optional read-only investigation, Cursor planning/build, verification, and independent review. Use for Azure Boards cards, work items, acceptance criteria, backlog/tasks specs, or card-to-PR workflows.
---

# Azure DevOps Card Flow

## Source boundaries

- Azure DevOps is authoritative for demand metadata and workflow state, but normal execution starts from its committed local projection.
- The existing `backlog/tasks/<id>-<slug>.md` is the repository-local execution contract and handoff artifact. New cards may already generate and commit this file.
- Repository code, tests, ADRs, and documentation are authoritative for observed implementation reality.
- Memory banks contain durable reusable knowledge, not card progress or transient task state.
- Never store credentials, access tokens, full MCP responses, or private attachment payloads in the spec.

## Local-first intake

- Find and read `backlog/tasks/<id>-*.md` before querying Azure DevOps or drafting anything.
- Use the committed local spec as the normal input for ChatGPT handoff, Codex investigation, Cursor planning/build, and Codex review.
- Azure DevOps MCP is optional. Query it only when the local spec is missing, its recorded revision is stale or unknown, comments/attachments may have changed, or the user explicitly requests live board data.
- Never block execution merely because Azure DevOps MCP is unavailable when the committed spec is sufficient and current.

## Mandatory execution contract

Before planning or editing, locate the existing spec by work-item ID under `backlog/tasks/`. Reuse it; never create a second task file for the same work item. Create a file from the template only when no generated/committed spec exists.

Ensure the local spec states:

1. objective;
2. normalized acceptance criteria;
3. **in scope**;
4. **out of scope**;
5. relevant constraints and decisions;
6. validation expected.

Do not infer permission to implement adjacent findings. Put them under out of scope, open questions, or follow-up work.

Use [the execution-spec template](references/execution-spec-template.md). Omit optional sections when they add no value, but never omit in-scope or out-of-scope boundaries.

## Branch convention

- Derive the branch from work-item ID and card title: `feature/<owner>/<id>-<slug>`.
- Default owner: `igor.grandin`. Explicit user or repository instructions may override it.
- Normalize the title to lowercase ASCII kebab-case, removing accents, punctuation, repeated separators, and leading/trailing hyphens.
- Example: `feature/igor.grandin/2528-envio-de-emails-convite-e-senha`.
- Use `scripts/new-card-branch.ps1` for deterministic generation and safe creation.
- Create/switch the branch only before implementation, from the intended base branch, with a clean worktree. Read-only analysis does not require a task branch.
- Reuse an existing matching branch. If remote or local work conflicts, stop and reconcile instead of creating a competing branch.

## Flow

### 1. Intake and specification

- Read the matching committed `backlog/tasks/<id>-*.md` as the baseline.
- Query the work item only when one of the local-first exceptions applies. When queried, compare its revision and material content with the local spec.
- Capture its ID, revision or retrieval date, link, description, acceptance criteria, relevant comments, attachments, and related work items.
- Complement the existing spec in place. Normalize only missing or ambiguous parts without silently changing business intent.
- If the card and committed spec differ materially, stop at the decision gate or record an explicit, reviewed amendment; do not overwrite one silently with the other.
- Flag contradictions, missing decisions, unverifiable acceptance criteria, and scope leakage.
- A normal ChatGPT conversation may draft the spec but cannot be assumed to access the local repository. The user or a repository-capable executor must save it.

### 2. Complexity gate

Proceed directly to planning when the card is explicit, local, consistent with repository documentation, and low risk.

Use a read-only `scout` investigation when any of these apply:

- legacy behavior or architecture is material;
- the card contradicts ADRs or current code;
- affected boundaries are uncertain or cross-cutting;
- security, identity, data migration, deployment, or external integration is involved;
- acceptance criteria cannot be mapped confidently to observable checks.

The scout updates only evidence, discrepancies, questions, risks, and suggested amendments. It does not implement.

### 3. Decision gate

- Return to the user/architect only for material product choices, architecture conflicts, changed scope, destructive actions, or acceptance criteria that remain ambiguous.
- Record resolved decisions in the spec. Promote durable architectural decisions to an ADR rather than leaving them only in the task file.

### 4. Cursor plan and build

- Give Cursor the work-item context, local spec, relevant scout evidence, and repository instructions.
- Before Build, confirm that the active branch matches the convention or an explicitly approved exception.
- In Plan Mode, map each acceptance criterion to changes and verification while respecting both scope lists.
- After approval, use Agent/Build to implement. Re-open the spec if repository evidence invalidates the plan.
- Record decisive tests and remaining limitations in the spec; do not paste noisy logs.

### 5. Independent review gate

Request a Codex `reviewer` before PR when the change affects identity/security, permissions, money, personal data, schemas, migrations, deployment, shared contracts, cross-cutting infrastructure, or otherwise has high regression impact.

The reviewer checks the diff against acceptance criteria, in-scope/out-of-scope boundaries, tests, security, compatibility, and documentation. Findings return to implementation; the reviewer does not silently expand scope.

### 6. Closeout

- Ensure every acceptance criterion is implemented, explicitly deferred, or blocked with evidence.
- Record the final verification summary and review disposition.
- Link the PR and work item without changing Azure DevOps state unless the user authorized that action.
- Promote only durable lessons or decisions to long-lived documentation or memory.
