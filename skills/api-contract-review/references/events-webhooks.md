# Events and webhooks

Review both schema compatibility and delivery semantics.

## Contract surface

- event identity, version, envelope, keys, correlation, tenant, and timestamps;
- field optionality, defaults, enum evolution, ordering, and unknown-field tolerance;
- partitioning, ordering scope, retention, replay, and dead-letter behavior;
- at-least-once or at-most-once implications, duplicates, retries, and idempotency;
- webhook signatures, rotation, replay protection, response deadlines, and retry schedule;
- producer ownership, consumer inventory, schema registry, and generated artifacts.

## Safe evolution

- Prefer additive evolution with tolerant consumers.
- Deploy consumers that tolerate the new shape before producers emit it.
- Version when semantics change incompatibly; do not use a version bump to hide an avoidable migration.
- Keep dual-publish or translation windows bounded and observable.
- Test duplicates, out-of-order delivery, partial failure, replay, and poison messages when the transport permits them.

State which guarantees come from the transport, which come from application logic, and which remain assumptions.
