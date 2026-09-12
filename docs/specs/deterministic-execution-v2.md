# Deterministic execution and routable root V2

- Status: implemented
- Date: 2026-09-12
- Scope: global harness policy, Codex routing, portable runners, installation, and regression tests

## Outcome

Make `orchestrator` a role rather than a model identity, prefer Luna Medium as the Codex root for clear procedural workflows such as `/execute`, and remove long-running deterministic waits and mechanical finalization from model loops.

## Repository validation

- OBSERVED FACT: the previous Codex adapter and model-routing reference fixed the primary orchestrator in the Sol family.
- OBSERVED FACT: the installer already provides a managed, copied `~/.agentic-harness/` snapshot and isolated-home tests.
- DECISION: extend that existing installed snapshot with stable `bin/` entrypoints and keep runtime artifacts under the system temporary directory by default.
- DECISION: use process-safe PowerShell primitives and small JSON inputs/results; do not add a runtime framework or dependency.

## Acceptance criteria

- AC-01: role and model are independent for the root; explicit user override wins.
- AC-02: procedural, clear workflows prefer Luna Medium; escalation follows Luna Medium -> Luna Max -> Terra High -> proportional Sol.
- AC-03: consequential decisions route first to Sol Low unless the user overrides the tier. Medium requires an insufficiency packet from Low and High requires one from Medium; mechanical work remains with the owning worker/runner.
- AC-04: long deterministic commands block inside a runner, write external logs/state, and emit compact terminal JSON for success, failure, and timeout.
- AC-05: authoritative project command semantics are preserved and model polling is forbidden when the runner exists.
- AC-06: finalization is manifest-driven, generic, read-only by default, and cannot stage or commit without explicit authorization.
- AC-07: installation exposes stable portable entrypoints and retains backups, materialization, three-agent limit, and bounded-context spawn rules.

## Non-goals

No LangGraph, workflow/DAG engine, daemon, queue, event bus, Python dependency, project-specific `/execute` change, or mandatory workflow compiler/cache is introduced.

## Future compatibility

V2.5 may compile authoritative workflow sources into a validated execution manifest. A deterministic fingerprint is only cache invalidation and must cover `/execute` plus its relevant dependencies; it is not "hash compilation". V3 may optionally let LangGraph consume those manifests and the V2 run-state schema for checkpoint/resume and approval transitions. The Markdown harness remains authoritative, direct execution remains available, and these runners remain the deterministic execution layer.

Keep three concepts separate: provider token cache, V2.5 workflow-manifest cache, and V2/V3 run state or checkpoint.
