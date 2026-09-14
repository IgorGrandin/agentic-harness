# Registered workflow V3.1

- Status: implemented structurally; real authenticated semantic execution remains outside this rehearsal.
- Date: 2026-09-14

## Decision

Registered workflow aliases are resolved deterministically by `bin/workflow-resolve.ps1`. The global `workflows/registry.json` maps aliases to logical ids and a project-local `.agentic-harness/workflows.json` maps those ids to a project-relative definition. A registered id always resolves to GRAPH; missing or invalid registry, binding, or definition fails closed. An explicit workflow definition remains GRAPH and an explicit ad-hoc executable remains DIRECT.

The compiler continues to fingerprint only declared project-relative sources. The binding is included explicitly in the definition's `sourceFiles`, so changing a binding or declared skill invalidates the cache without dependency inference.

## Evidence contract

`policy.requiredEvidence` may require an `observed` evidence item from a semantic node. The semantic response schema accepts structured evidence, and finalization deterministically blocks until every required item is present with type `observed`. No extra model call is used to inspect a structured boolean.

## Finalization contract

Round logs may target an external path only when the manifest explicitly declares `external`, `allowExternal`, and `allowedRoots`, and the caller supplies `-AllowWrite`. Environment variables are expanded deterministically, the resolved path must remain under an allowed root, and the implementation creates a header once then appends exactly one UTF-8 line. Repository-local round logs retain the existing containment rule. The implementation does not use CSV import/export cmdlets and does not rewrite the existing file.

## Non-goals

- No change to the corporate `source-command-execute/SKILL.md`.
- No BrixBroker-specific paths or aliases in the global runtime.
- No redesign of V2.1, V2.5, or the existing V3 graph/checkpoint architecture.
