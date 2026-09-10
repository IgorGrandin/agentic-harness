# Model routing policy

Role, model, and skill are independent axes:

- Role answers who is responsible.
- Model answers how much capability the task needs.
- Skill answers which task-specific procedure should be loaded.

Choose the processing lane before the model tier. Delegation is justified by expected net savings or useful context isolation, not merely because work exceeds the microtask budget.

## Microtask direct-execution exception

The Sol High orchestrator may execute directly only when all of these remain true:

- the requested outcome and target are explicit;
- the change is local, reversible, and carries no contract, data, security, architecture, or operational risk;
- at most one targeted inspection, one small edit, and one focused check are needed;
- spawning and summarizing a worker would cost more than completing the work.

Do not create a spec, plan, architecture comparison, subagent, or routing log for this lane. Reclassify before continuing if the task needs broader exploration, multiple meaningful edits, or additional verification.

## Sol reasoning — proportional orchestration

Keep the primary orchestrator and spec author in the Sol family, but do not require high reasoning for every request:

- **Low:** microtasks with an explicit target and no material decision.
- **Medium:** clear bounded intake, routing, and synthesis.
- **High:** consequential work with the signals below.

Choose GPT-5.6 Sol with high reasoning when any of these apply:

- requirements are ambiguous or require tradeoffs;
- architecture, security, concurrency, data integrity, migrations, or public contracts are involved;
- impact crosses multiple modules or domains;
- root cause is obscure or evidence conflicts;
- verification is expensive or failure is costly;
- the task requires synthesizing a large repository surface.

## Luna Medium — bounded efficiency lane

Choose GPT-5.6 Luna with medium reasoning when the task is low risk, tightly bounded, and independently verifiable, such as:

- read-only scouting, file discovery, or call-site inventory;
- mechanical edits with an exact transformation;
- focused documentation updates;
- a localized test or small bug with clear reproduction and expected behavior.

Luna must not begin implementation merely to discover that the task is complex.

For work in this lane, use Luna Medium only when cheaper execution or keeping noisy tool output out of the primary context is likely to recover spawn and synthesis overhead. Otherwise Sol executes directly with proportional reasoning. A worker performs the smallest decisive verification; Sol does not repeat it unless relevant files or inputs changed afterward.

## Luna Max — narrow reasoning escalation

Raise Luna from medium to max only when the task remains narrow, low risk, and independently verifiable but needs unusually deep local tracing or several contained edge cases. Escalate to Terra High instead when the scope broadens across components, the objective becomes non-obvious, or risk becomes material.

## Terra High — intermediate escalation lane

Choose GPT-5.6 Terra with high reasoning when Luna detects meaningful complexity but the task remains well bounded and does not need frontier architectural judgment. Typical signals:

- moderate cross-file reasoning with a clear objective;
- a localized but non-obvious bug after the reproduction path is known;
- review or verification requiring deeper tracing than Luna can provide;
- a contained implementation with several edge cases and decisive tests.

Escalate Terra High to Sol High when ambiguity, risk, or system-wide judgment remains material.

## Early escalation gate

Before implementation, scout only enough to estimate:

- ambiguity of desired behavior;
- number of components and contracts affected;
- risk to security, data, compatibility, or operations;
- availability and cost of decisive verification;
- presence of conflicting evidence or missing ownership.

Raise Luna Medium to Luna Max when only reasoning depth increases and the lane stays narrow. Escalate immediately to Terra High when the task broadens beyond Luna but remains bounded. Escalate directly to Sol High when one high-risk signal appears, several moderate signals combine into architectural uncertainty, or the spec itself needs revision. Return a compact escalation packet: observed scope, evidence, unresolved questions, risk, and recommended next tier. Do not repeat the same work in both lanes.

During execution, escalate on newly discovered cross-cutting impact, failed assumptions, nondeterminism, or inability to define a decisive test after one focused investigation cycle.

The orchestrator stays in the Sol family and owns the specification, routing, synthesis, and any materially different product or architecture decision. Use high reasoning only when consequential signals justify it.

## Codex spawn enforcement

When Codex delegates, every spawn declares the selected `model` and `reasoning_effort`; do not rely on the global default to override inheritance. Use `fork_turns: "none"` by default and send a self-contained task packet. A positive limited turn count is allowed only when those turns are the smallest useful context. Never use `fork_turns: "all"` when selecting Luna or Terra because the full-history fork inherits the primary Sol model.

A Sol subagent requires an explicit consequential signal from this rubric and a routing-log reason. Routine scouting, repository discovery, bounded implementation, and focused verification do not qualify. If no consequential signal exists, execute directly with proportional effort or use Luna or Terra as appropriate.
