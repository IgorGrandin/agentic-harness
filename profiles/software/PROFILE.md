## Software Engineering Profile

Runtime baseline: Codex.

### SDD workflow

- For software work, use the `sdd-workflow` skill when the request is a bug, feature, discovery, refactor, or review.
- Route before expanding the workflow. Explicit, local, low-risk work uses the skill's fast lane with no spec, plan, subagent, or routing log.
- Code and tests must trace back to the active Markdown specification or an explicit user request.
- Separate thinking from execution: an imported portable spec is validated against repository reality before execution, and material discrepancies become amendments.

### Model routing

- Keep orchestration and specification on GPT-5.6 Sol with proportional reasoning: low for simple work, medium for bounded synthesis, and high only for consequential work.
- Delegate to Luna Medium only when cheaper execution or context isolation is expected to outweigh spawn and synthesis overhead.
- Use Luna Max for narrow deep reasoning, Terra High for broader bounded complexity, and Sol High for consequential judgment.
- Escalate before implementation when the selected lane is clearly insufficient; do not require a failed attempt.
- Follow `sdd-workflow/references/model-routing.md` for the detailed rubric.

### Reusable coding agents

- Reusable roles are `scout`, `implementer`, `verifier`, `reviewer`, and `architect_escalation`.
- Choose the role from the activity, the model from complexity, and the skill from the required procedure. These are independent axes.
- Delegation and parallelism require a material net gain; dependent work remains sequential.
- Prefer one writer at a time. Concurrent writers require isolated Git worktrees and non-overlapping ownership.
- Run at most three subagents concurrently during V1.
- Log only escalations, parallel execution, or non-obvious routing decisions using `sdd-workflow/references/subagent-orchestration.md`.

### Engineering execution

- For diagnosis or review, inspect and report; do not implement unless requested.
- For requested changes, make scoped edits and run the smallest decisive verification.
- Accept passing worker evidence unless relevant files or inputs changed afterward.
- Add an independent verifier or reviewer only when independence materially improves confidence.
- Run broad suites only for cross-cutting changes, contracts, schemas, security boundaries, build systems, shared infrastructure, or when no narrower decisive check exists.
- Apply specialist skills only when their decision surface is present: debugging, architecture, API compatibility, database safety, frontend design, or UI/UX quality.
