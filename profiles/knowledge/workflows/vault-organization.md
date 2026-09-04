# Existing vault organization workflow

Status: planned; no vault mutation is authorized by this document.

`INVENTORY -> CLASSIFY -> PROPOSE STRUCTURE -> PROPOSE LINKS / PROPERTIES / TAGS -> HUMAN REVIEW -> APPLY -> VERIFY`

## Gates

- Inventory and classification are read-only.
- Proposals distinguish observed structure from inferred intent.
- Apply requires explicit human approval of a bounded change set.
- Bulk rename, move, or delete requires separate strong confirmation and a recoverable plan.
- Verification compares the approved proposal with the resulting vault and reports unresolved links or metadata drift.
