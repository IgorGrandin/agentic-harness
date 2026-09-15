# Single execution kernel

The harness has one execution kernel for ordinary tasks and `/execute`.
`/execute` is only a constraints overlay: it adds declared evidence, review,
gate, and finalization requirements to the same task loop. It does not select
the root agent, create a second workflow engine, or introduce a graph runtime.

The root agent is selected by the host. The control plane uses the configured
default for the host when no explicit model is requested. Semantic work is
performed by native workers; deterministic scripts only validate declarations,
enforce safety, wait for processes, and record bounded receipts.

When a worker fails before producing an accepted result, the kernel records the
failure and asks the host to replace that worker with an equivalent role and a
bounded context packet. Replacement is at most one active worker per phase;
the kernel never retries by silently replaying arbitrary side effects.

Every worker receives progressive disclosure context: task intent, applicable
constraints, the smallest declared sources, and the last bounded receipt.
Context and output budgets are explicit and validated before dispatch.
