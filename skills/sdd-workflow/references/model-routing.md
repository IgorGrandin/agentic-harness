# Model routing policy

Role, model, and skill are independent axes:

- Role answers who is responsible.
- Model answers how much capability the task needs.
- Skill answers which task-specific procedure should be loaded.

Choose the processing lane before the model tier. Delegation is justified by expected net savings or useful context isolation, not merely because work exceeds the microtask budget.

Consequentiality selects who must make a decision and the reasoning tier for that judgment. It does not require the same agent or tier to perform every mechanical tool call, inspection, edit, or check. Keep bounded execution with Luna or Terra when appropriate and escalate a compact decision packet to Sol only for the consequential choice.

## Root routing

The orchestrator is a role, not a model identity. Select the root model after classifying the work, and honor an explicit user override. Prefer Luna Medium root for clear procedural or recurring workflows, implementation against an authoritative spec or validated manifest, and `/execute`-style execution. Root context remains premium at every model tier.

Use this restrictive ladder:

1. Luna Medium for procedural, bounded execution.
2. Luna Max when only local reasoning depth increases and the work remains narrow and authorized.
3. Terra High when bounded complexity expands across components or requires broader synthesis without a material decision.
4. Sol Low for every first material-decision escalation. Medium and High are evidence-driven re-escalations, not initial routing choices.

## Microtask direct-execution exception

The selected root may execute directly only when all of these remain true:

- the requested outcome and target are explicit;
- the change is local, reversible, and carries no contract, data, security, architecture, or operational risk;
- at most one targeted inspection, one small edit, and one focused check are needed;
- spawning and summarizing a worker would cost more than completing the work.

Do not create a spec, plan, architecture comparison, subagent, or routing log for this lane. Reclassify before continuing if the task needs broader exploration, multiple meaningful edits, or additional verification.

## Sol reasoning — proportional decision authority

Use Sol for material decisions, not permanent mechanical orchestration:

- **Low:** a bounded, well-framed consequential decision.
- **Medium:** a consequential decision requiring broader synthesis or material ambiguity resolution.
- **High:** exceptional judgment where risk, ambiguity, or blast radius genuinely requires the strongest tier.

Unless the user explicitly overrides the tier, the Sol ladder is sequential and MUST NOT skip rungs:

1. Every first Sol call uses Low, even when the decision concerns architecture, security, data, migration, or a public contract.
2. Medium is allowed only after Low returns a compact insufficiency packet naming the unresolved decision, evidence already considered, remaining ambiguity or synthesis need, and why more evidence or another Low pass is insufficient.
3. High is allowed only after Medium returns the equivalent packet and identifies exceptional remaining consequence or ambiguity.

Do not preselect Medium or High because a task looks difficult, spans many files, has a large context, or has available budget. Consequentiality decides whether Sol must decide; observed insufficiency decides whether reasoning rises above Low.

MUST escalate to Sol Low when any of these apply; increase reasoning only through the sequential evidence gate above:

- authoritative instructions conflict with repository reality;
- a product, architecture, scope, or release decision is required;
- auth, security, or permissions require a non-mechanical decision;
- data integrity or a migration is ambiguous or consequential;
- an important public contract or compatibility boundary may change;
- evidence is materially contradictory;
- a material reviewer finding has no obvious accepted mechanical correction;
- human authorization is required or the worker should not decide alone.

MUST NOT escalate only for file reads, clear-spec edits, config/Markdown changes, tests/builds, process waiting, Git inspection, mechanical metadata, applying an existing decision, or an accepted mechanical correction.

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

Escalate Terra High to Sol Low when ambiguity, risk, or system-wide judgment becomes material.

## Early escalation gate

Before implementation, scout only enough to estimate:

- ambiguity of desired behavior;
- number of components and contracts affected;
- risk to security, data, compatibility, or operations;
- availability and cost of decisive verification;
- presence of conflicting evidence or missing ownership.

Raise Luna Medium to Luna Max when only reasoning depth increases and the lane stays narrow. Escalate to Terra High when the task broadens but remains bounded. Escalate to Sol Low when a material decision appears or the spec itself needs revision. Return a compact escalation packet: observed scope, evidence, unresolved questions, and risk. Do not recommend Medium or High before Low evaluates the decision, and do not repeat the same work in both lanes.

During execution, escalate on newly discovered cross-cutting impact, failed assumptions, nondeterminism, or inability to define a decisive test after one focused investigation cycle.

The orchestrator role owns routing and synthesis. Sol owns materially different product or architecture decisions when escalated; use high reasoning only when consequential signals justify it.

Keep every root thin: consume capsules, escalation packets, and completion packets instead of full skill bodies, transcripts, or raw command output. While delegated ownership is active, do not repeat the worker's investigation or poll its process unless failure, conflicting evidence, or a material decision requires intervention. Integration and final verification may run after merged changes or shared inputs invalidate the worker's earlier evidence.

## Codex spawn enforcement

When Codex delegates, every spawn declares the selected `model` and `reasoning_effort`; do not rely on the global default to override inheritance. Use `fork_turns: "none"` by default and send a self-contained task packet. A positive limited turn count is allowed only when those turns are the smallest useful context. Never use `fork_turns: "all"` when selecting Luna or Terra because the full-history fork inherits the primary Sol model.

A Sol subagent requires an explicit consequential signal from this rubric and a routing-log reason. Routine scouting, repository discovery, bounded implementation, and focused verification do not qualify. If no consequential signal exists, execute directly with proportional effort or use Luna or Terra as appropriate.
