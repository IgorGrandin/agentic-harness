# Portable specification contract

An imported brainstorming spec is a proposal until validated against the repository.

## Minimum useful fields

- Title and status
- Problem and desired outcome
- Context and constraints
- In scope / out of scope
- Observed facts, assumptions, and open questions
- Proposed behavior or design
- Acceptance criteria with stable IDs (`AC-01`, `AC-02`, ...)
- Risks and alternatives considered
- Verification strategy
- Repository validation notes
- Decisions and amendments

Fields may be omitted when genuinely irrelevant. Do not fill gaps with invented facts.

## Repository validation

For each material claim, mark it as confirmed, contradicted, or unresolved and cite repository evidence by file/symbol/test where useful. If validation changes the design, add an amendment with rationale and identify affected acceptance criteria.

## Traceability

Implementation and verification notes should reference acceptance criterion IDs. Keep a concise mapping rather than duplicating the spec in code comments.
