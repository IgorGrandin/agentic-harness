# Subagent orchestration

Use subagents only when delegation reduces context pollution, improves independent verification, or parallelizes genuinely independent work.

Parallelism is a router decision, not a default. V1 permits at most three concurrent subagents.

## Roles

- `scout`: read-only evidence gathering, scope mapping, and complexity estimation.
- `implementer`: scoped code or documentation changes against explicit acceptance criteria.
- `verifier`: run or design decisive checks and report evidence; do not repair failures unless separately authorized.
- `reviewer`: independently inspect changes for correctness, risk, regressions, and missing tests.
- `architect_escalation`: resolve an escalation packet, compare material options, or recommend a spec amendment.

Roles do not imply a model, technology, or skill. Select the model from the routing rubric. Mention a skill in the spawn task only when that skill applies.

## Default flow

1. The Sol High orchestrator owns intake, the active spec, routing, and synthesis.
2. Spawn a Luna Max worker for a bounded activity.
3. The worker stops early and returns an escalation packet when its lane is exceeded.
4. Reassign the unresolved activity to Terra High, or directly to Sol High when risk or ambiguity is high.
5. Do not repeat evidence gathering already captured in the packet.
6. Keep a single write owner. Use separate verifier and reviewer roles after implementation when proportionate.

## Parallelism gate

Before spawning more than one subagent, the orchestrator maps each candidate task's inputs, outputs, write surface, and dependencies.

Parallelize only when all are true:

- no candidate needs another candidate's unfinished output;
- scopes and completion conditions are independently testable;
- concurrent work provides a material latency or context-isolation gain;
- coordination and synthesis cost is smaller than the expected gain;
- permissions and external side effects do not require serial ordering.

Keep execution sequential when any are true:

- task B consumes a decision, artifact, or evidence produced by task A;
- tasks may edit the same files, symbols, schema, generated artifacts, or shared state;
- one result can invalidate or materially reshape the next task;
- verification must observe the integrated result;
- the work is too small to recover spawning and synthesis overhead.

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

Keep the log in the active spec when one exists; otherwise include it in the orchestrator handoff. Do not put transient routing events in the global memory bank.

One line per material decision:

```text
R01 role=scout tier=luna/max action=spawn reason="bounded read-only scope" result=completed
R02 role=implementer tier=luna/max action=escalate reason="public contract spans 3 modules" next=terra
R03 role=architect_escalation tier=terra/high action=escalate reason="security tradeoff changes spec" next=sol/high
R04 role=scout tier=luna/max action=parallel reason="2 independent read-only traces" width=2
R05 role=implementer tier=luna/max action=sequential reason="task B consumes task A output"
R06 role=implementer tier=luna/max action=parallel reason="disjoint write ownership" width=2 isolation=worktree
```

Allowed `action` values: `spawn`, `parallel`, `sequential`, `continue`, `escalate`, `stop`. Keep `reason` to one discriminating signal. Record outcomes, not chain-of-thought.

## Escalation packet

Return only:

- completed scope and reusable evidence;
- newly discovered complexity or risk;
- unresolved decision;
- recommended next tier and why;
- files or tests the next agent should inspect.
