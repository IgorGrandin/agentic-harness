# Refactor workflow

1. State the invariant behavior that must not change and the reason for refactoring.
2. Map callers, contracts, tests, and operational assumptions.
3. Define measurable completion and rollback boundaries.
4. Prefer small reversible slices when the change is broad.
5. When authorized, preserve behavior first; separate functional changes unless explicitly included.
6. Verify equivalence plus the intended structural improvement.

Escalate when behavior cannot be characterized, compatibility boundaries are unclear, or migration must be coordinated.
