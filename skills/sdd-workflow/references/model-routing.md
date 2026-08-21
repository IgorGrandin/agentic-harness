# Model routing policy

Role, model, and skill are independent axes:

- Role answers who is responsible.
- Model answers how much capability the task needs.
- Skill answers which task-specific procedure should be loaded.

## Sol High — default for consequential work

Choose GPT-5.6 Sol with high reasoning when any of these apply:

- requirements are ambiguous or require tradeoffs;
- architecture, security, concurrency, data integrity, migrations, or public contracts are involved;
- impact crosses multiple modules or domains;
- root cause is obscure or evidence conflicts;
- verification is expensive or failure is costly;
- the task requires synthesizing a large repository surface.

## Luna Max — bounded efficiency lane

Choose GPT-5.6 Luna with max reasoning when the task is low risk, tightly bounded, and independently verifiable, such as:

- read-only scouting, file discovery, or call-site inventory;
- mechanical edits with an exact transformation;
- focused documentation updates;
- a localized test or small bug with clear reproduction and expected behavior.

Luna must not begin implementation merely to discover that the task is complex.

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

Escalate immediately to Terra High when the task exceeds Luna but remains bounded. Escalate directly to Sol High when one high-risk signal appears, several moderate signals combine into architectural uncertainty, or the spec itself needs revision. Return a compact escalation packet: observed scope, evidence, unresolved questions, risk, and recommended next tier. Do not repeat the same work in both lanes.

During execution, escalate on newly discovered cross-cutting impact, failed assumptions, nondeterminism, or inability to define a decisive test after one focused investigation cycle.

The orchestrator stays on Sol High and owns the specification, routing, synthesis, and any materially different product or architecture decision.
