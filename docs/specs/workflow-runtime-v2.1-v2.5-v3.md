# Deterministic workflow runtime V2.1, V2.5, and V3

- Status: implemented structurally; live authenticated E2E pending independent verification
- Date: 2026-09-14

## Decision

V3 makes LangGraph the outer orchestrator after a small Codex bootstrap. The root resolves an explicit source and invokes `agentic-execute.ps1`; it does not dispatch nodes or poll subprocesses. DIRECT mode remains available only for an explicit ad-hoc executable. GRAPH mode consumes a validated declarative workflow manifest.

## Contract

`workflow-compile.ps1` accepts only a `workflow-definition` JSON document. `sourceFiles`, `nodes`, `edges`, and `policy` are declared by that document; no project convention, BrixBroker path, Cursor path, command, dependency, working directory, or argument list is inferred. The compiler fingerprints normalized declared paths and contents, and a cache hit returns `compilerCalls: 0`.

Nodes are `agent`, `decision`, `command`, and `finalization`. Semantic nodes use the provider-agnostic executor interface; the first adapter invokes authenticated `codex exec --ephemeral --json --ignore-user-config --ignore-rules` without an API key. The response is parsed from JSONL and must conform to the bounded decision object. Routing comes from manifest configuration; `architect_escalation` is forced to Sol Low.

Commands and gates call `agentic-run.ps1`, which preserves argv items with `ProcessStartInfo.ArgumentList`, including empty strings and Windows metacharacters. Finalization invokes `agentic-finalize.ps1` only where both the node declaration and runtime authorization allow it. Raw process logs remain in the machine runtime root.

## Invariants

- A gate has an `APPROVED` reviewer predecessor.
- A finalization edge can originate only at `GATE(GREEN)`.
- A finding routes through correction and re-review before a gate can run.
- Gate failure blocks finalization.
- SQLite checkpoints are keyed by run ID and reject a changed manifest fingerprint on resume.
- No production scenario fields or synthetic LLM counters control runtime behavior.

## Installation and limits

`scripts/install.ps1` stages a replacement `~/.agentic-harness/runtime/python` venv, installs only a transitively hash-locked `runtime/requirements-langgraph.lock`, verifies imports and versions, then swaps it atomically while retaining the previous venv for rollback. The checked-in two-package input is not accepted as an install lock: in a separately authorized networked installation phase generate the transitive hash lock with `pwsh -File runtime/generate-langgraph-lock.ps1 -BootstrapPython <python>`. Checkpoints, raw logs, cache, and virtual environments remain outside project worktrees.

The installer removes `architect_escalation.toml` only when it is byte-for-byte the exact duplicate of canonical `architect-escalation.toml`; otherwise it stops rather than deleting user-owned content.

Deterministic unit tests exercise compilation, cache invalidation, manifest rejection, argv preservation, JSONL/schema parsing, routing, correction/re-review, finalization blocking, and checkpoint fingerprint handling. A live Codex call is deliberately not repeated; it remains an independent verifier action because it consumes authenticated service capacity.
