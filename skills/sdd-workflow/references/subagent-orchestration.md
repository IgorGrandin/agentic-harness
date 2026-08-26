# Subagent orchestration

Use one sequential subagent for bounded work larger than a microtask. This keeps implementation and noisy tool output out of the Sol orchestrator's context even when parallelism would provide no benefit.

Parallelism is a router decision, not a default. V1 permits at most three concurrent subagents.

## Delegation gate

Delegation and parallelism are separate decisions:

- **Microtask:** Sol may execute directly within the one-inspection, one-edit, one-check budget because spawn overhead would dominate.
- **Bounded task:** spawn exactly one Luna Medium worker and wait sequentially. Raise it to Luna Max only for a narrow but reasoning-heavy activity.
- **Consequential task:** route to Terra High or Sol High using the model rubric; delegate bounded supporting activities when useful.

If a presumed microtask exceeds its budget, stop direct execution and reclassify it. Do not use the primary agent to finish a bounded task simply because it has already started exploring.

## Roles

- `scout`: read-only evidence gathering, scope mapping, and complexity estimation.
- `implementer`: scoped code or documentation changes against explicit acceptance criteria.
- `verifier`: run or design decisive checks and report evidence; do not repair failures unless separately authorized.
- `reviewer`: independently inspect changes for correctness, risk, regressions, and missing tests.
- `architect_escalation`: resolve an escalation packet, compare material options, or recommend a spec amendment.

Roles do not imply a model, technology, or skill. Select the model from the routing rubric. Mention a skill in the spawn task only when that skill applies.

## Default flow

1. The Sol High orchestrator owns intake, the active spec, routing, and synthesis.
2. Execute only genuine microtasks directly; otherwise spawn a Luna Medium worker for a bounded activity, including serial implementation.
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

## Lifecycle and handoff

Close completed threads immediately after consuming their result. At handoff, leave zero active or idle agents unless explicit monitoring requires one; threads are not retained for history alone. After two consecutive no-progress windows totaling 10 minutes, inspect once, then interrupt and close the thread if it is complete, redundant, or stuck.

## Multiple writers and isolation

Prefer a single writer. When concurrent implementation has a real benefit:

1. Assign non-overlapping file or component ownership.
2. Create one isolated Git worktree per writer before either agent edits.
3. Give each writer its exact worktree path, acceptance criteria, and forbidden overlap.
4. Keep integration, conflict resolution, integrated verification, and final review sequential under the orchestrator.
5. If worktree isolation is unavailable or safe ownership cannot be defined, serialize the writers.

Read-only scouts, reviewers, and verifiers may share the main working tree when they do not mutate state.

## Compact routing log

Keep the log in the active spec when one exists; otherwise include it in the orchestrator handoff. Do not put transient routing events in the global memory bank. A genuine microtask needs no routing log.

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
