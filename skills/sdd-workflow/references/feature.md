# Feature workflow

1. Confirm user outcome, boundaries, constraints, and explicit non-goals.
2. Inspect existing extension points and conventions before selecting a design.
3. Choose the smallest change surface that satisfies the outcome. Before adding a component, abstraction, dependency, persistence mechanism, or configuration/startup change, identify the acceptance criterion that requires it and why an existing path is insufficient.
4. Exclude future-proofing and hypothetical extensibility unless the request or repository evidence makes them current requirements.
5. Compare alternatives only where the choice materially affects cost, compatibility, or maintainability.
6. Define acceptance criteria and verification before implementation.
7. When authorized, implement in reviewable slices that preserve the active spec.
8. Verify end-to-end behavior and relevant failure paths.

Pause for a user decision when repository reality requires a materially different product outcome.
