# Deterministic workflow runtime V2.1, V2.5, and V3

- Status: implemented structurally; live authenticated E2E pending independent verification
- Date: 2026-09-14

## Decision

The native architecture keeps Codex/Cursor/other adapters as semantic orchestrators after a small deterministic bootstrap. The root resolves an explicit source and invokes `agentic-execute.ps1`; it does not shadow delegated work or poll subprocesses. DIRECT mode remains available only for an explicit ad-hoc executable. NATIVE mode consumes a validated declarative workflow contract.

## Contract

`workflow-compile.ps1` accepts only a `workflow-definition` JSON document. `sourceFiles`, `nodes`, `edges`, and `policy` are declared by that document; no project convention, BrixBroker path, Cursor path, command, dependency, working directory, or argument list is inferred. The compiler fingerprints normalized declared paths and contents, and a cache hit returns `compilerCalls: 0`.

Nodes are `agent`, `decision`, `command`, and `finalization`. Semantic nodes use the provider-agnostic executor interface; the first adapter invokes authenticated `codex exec --ephemeral --json --ignore-user-config --ignore-rules` without an API key. The response is parsed from JSONL and must conform to the bounded decision object. Routing comes from manifest configuration; `architect_escalation` is forced to Sol Low.

Commands and gates call `agentic-run.ps1`, which preserves argv items with `ProcessStartInfo.ArgumentList`, including empty strings and Windows metacharacters. Finalization invokes `agentic-finalize.ps1` only where both the node declaration and runtime authorization allow it. Raw process logs remain in the machine runtime root.

## Invariants

- A gate has an `APPROVED` reviewer predecessor.
- A finalization edge can originate only at `GATE(GREEN)`.
- A finding routes through correction and re-review before a gate can run.
- Gate failure blocks finalization.
- JSON state is keyed by run ID and rejects a changed contract fingerprint on resume.
- No production scenario fields or synthetic LLM counters control runtime behavior.

## Installation and limits

`scripts/install.ps1` installs portable scripts and declarative assets only. State, receipts, raw logs, and cache remain outside project worktrees under the machine runtime directory.

The installer removes `architect_escalation.toml` only when it is byte-for-byte the exact duplicate of canonical `architect-escalation.toml`; otherwise it stops rather than deleting user-owned content.

Deterministic unit tests exercise compilation, cache invalidation, contract rejection, argv preservation, routing, correction/re-review, receipt guards, finalization blocking, and JSON state fingerprint handling. A live native-agent call is deliberately not repeated; it remains an independent verifier action because it consumes authenticated service capacity.
