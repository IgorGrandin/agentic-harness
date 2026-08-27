# Subagent orchestration

Use a subagent only when cheaper execution, context isolation, independent verification, or parallelism is expected to outweigh spawn and synthesis overhead.

Parallelism is a router decision, not a default. V1 permits at most three concurrent subagents.

## Delegation gate

Delegation and parallelism are separate decisions:

- **Microtask:** Sol may execute directly within the one-inspection, one-edit, one-check budget because spawn overhead would dominate.
- **Bounded task:** execute directly or use one Luna Medium worker when delegation has a material expected net gain. Raise it to Luna Max only for a narrow but reasoning-heavy activity.
- **Consequential task:** route to Terra High or Sol High using the model rubric; delegate bounded supporting activities when useful.

If a presumed microtask exceeds its budget, reclassify it and choose direct or delegated execution using the net-gain gate.

## Roles

- `scout`: read-only evidence gathering, scope mapping, and complexity estimation.
- `implementer`: scoped code or documentation changes against explicit acceptance criteria.
- `verifier`: run or design decisive checks and report evidence; do not repair failures unless separately authorized.
- `reviewer`: independently inspect changes for correctness, risk, regressions, and missing tests.
- `architect_escalation`: resolve an escalation packet, compare material options, or recommend a spec amendment.

Roles do not imply a model, technology, or skill. Select the model from the routing rubric. Mention a skill in the spawn task only when that skill applies.

## Default flow

1. The Sol orchestrator owns intake, the active spec, routing, and synthesis with reasoning proportional to the task.
2. Execute simple and bounded work directly when handoff overhead dominates; otherwise use Luna Medium for a bounded activity.
3. The worker stops early and returns an escalation packet when its lane is exceeded.
4. Reassign the unresolved activity to Terra High, or directly to Sol High when risk or ambiguity is high.
5. Do not repeat evidence gathering already captured in the packet.
6. Keep a single write owner. For low-risk work, the implementer supplies focused verification and no separate verifier or reviewer is spawned by default.
7. Sol consumes the worker's summarized evidence and does not repeat a passing check unless relevant files or test inputs changed after the worker ran it.

## Parallelism gate

Before spawning more than one subagent, the orchestrator maps each candidate task's inputs, outputs, write surface, and dependencies.

Parallelize only when all are true:

- no candidate needs another candidate's unfinished output;
- scopes and completion conditions are independently testable;
- concurrent work provides a material latency or context-isolation gain;
- coordination and synthesis cost is smaller than the expected gain;
- permissions and external side effects do not require serial ordering.

Keep delegated execution sequential when any are true:

- task B consumes a decision, artifact, or evidence produced by task A;
- tasks may edit the same files, symbols, schema, generated artifacts, or shared state;
- one result can invalidate or materially reshape the next task;
- verification must observe the integrated result;
- the tasks are dependent or share mutable state.

When the entire request is too small to recover spawning and synthesis overhead, use the microtask direct-execution exception instead of labeling it delegated sequential work.

Use no more agents than independent work items and never exceed three concurrently. A free slot is not a reason to fill it.

## Multiple writers and isolation

Prefer a single writer. When concurrent implementation has a real benefit:

1. Assign non-overlapping file or component ownership.
2. Create one isolated Git worktree per writer before either agent edits.
3. Give each writer its exact worktree path, acceptance criteria, and forbidden overlap.
4. Keep integration, conflict resolution, integrated verification, and final review sequential under the orchestrator.
5. If worktree isolation is unavailable or safe ownership cannot be defined, serialize the writers.

Read-only scouts, reviewers, and verifiers may share the main working tree when they do not mutate state.

## Compact routing log

Log only escalations, parallel execution, or a non-obvious routing decision. Keep the log in the active spec when one exists; otherwise include it in the orchestrator handoff. Routine direct or sequential work needs no log, and transient events never belong in global memory.

One line per material decision:

```text
R01 role=scout tier=luna/medium action=spawn reason="bounded read-only scope" result=completed
R02 role=implementer tier=luna/medium action=escalate reason="narrow path needs deeper local tracing" next=luna/max
R03 role=implementer tier=luna/max action=escalate reason="public contract spans 3 modules" next=terra/high
R04 role=architect_escalation tier=terra/high action=escalate reason="security tradeoff changes spec" next=sol/high
R05 role=scout tier=luna/medium action=parallel reason="2 independent read-only traces" width=2
R06 role=implementer tier=luna/medium action=sequential reason="task B consumes task A output"
R07 role=implementer tier=luna/medium action=parallel reason="disjoint write ownership" width=2 isolation=worktree
```

Allowed `action` values: `spawn`, `parallel`, `sequential`, `continue`, `escalate`, `stop`. Keep `reason` to one discriminating signal. Record outcomes, not chain-of-thought.

## Escalation packet

Return only:

- completed scope and reusable evidence;
- newly discovered complexity or risk;
- unresolved decision;
- recommended next tier and why;
- files or tests the next agent should inspect.
