# Agentic Harness V4

## Source of truth

V4 consolidates ordinary tasks and `/execute` on one native-agent kernel.
`/execute` is a constraints overlay, not a separate orchestration engine.

| Surface | V4 decision | Treatment |
| --- | --- | --- |
| Native task loop | one kernel with host-selected root | KEEP |
| `/execute` review, gate, receipts | constraints overlay on the kernel | SIMPLIFY |
| PowerShell runner and safety guards | deterministic boundary | KEEP |
| Legacy graph/Python runtime | no operational dependency | REMOVE |
| Existing workflow contract scripts | compatibility reader during migration | KEEP temporarily |

## Contract

The kernel receives a task, optional constraints, declared context sources, and
bounded budgets. It returns a plan for a native worker. A worker failure emits
a replacement request with the same role and a fresh bounded context packet;
the kernel does not replay side effects. The host remains responsible for
semantic decisions and root selection.

Required invariants are: external runtime state, no credentials in the
repository, one active worker per phase, explicit source allowlists, and
terminal deterministic runner results.

## Measurable completion

- `bin/agentic-kernel.ps1` validates the request and emits a compact plan.
- Context and output budgets are positive and within the kernel maximum.
- Failure/replacement behavior is covered by a deterministic fixture.
- Materialization, portability, and existing native-contract regressions stay
  green.

The compatibility scripts under `bin/workflow-*.ps1` remain until all existing
project bindings are migrated; they are not a second runtime.
