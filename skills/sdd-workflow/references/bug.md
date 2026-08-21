# Bug workflow

1. Establish expected versus observed behavior and reproduction evidence.
2. Bound the affected path and regression surface before editing.
3. Separate candidate causes from confirmed root cause.
4. Define acceptance criteria including a regression check.
5. When authorized, implement the smallest root-cause fix consistent with project conventions.
6. Verify reproduction is resolved and nearby behavior remains intact.

Escalate early when the bug involves nondeterminism, concurrency, corruption, security, or unclear ownership across components.
