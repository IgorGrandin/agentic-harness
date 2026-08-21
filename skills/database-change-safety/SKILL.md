---
name: database-change-safety
description: Plan or review database schema changes, migrations, backfills, constraints, indexes, and persistence changes where existing data, concurrency, locks, compatibility, or rollback matter. Do not use for read-only query work unless it presents a material production-performance or correctness risk.
---

# Database change safety

Make database changes compatible with existing data, mixed application versions, operational limits, and a verifiable rollout.

## Establish reality

1. Identify the database engine and version, migration framework, schema source of truth, data volume or growth assumptions, deployment topology, and existing project conventions.
2. Trace all readers and writers of the affected data, including jobs, reports, integrations, replicas, caches, and generated models.
3. State the invariants that must hold before, during, and after rollout.
4. Separate schema transition, application transition, data movement, validation, and cleanup.

## Route by change type

- For tables, columns, types, constraints, indexes, or destructive cleanup, read [references/schema-rollout.md](references/schema-rollout.md).
- For backfills, transformations, re-keying, or large data repair, read [references/data-movement.md](references/data-movement.md).
- Read both only when the rollout genuinely combines those concerns.

## Safety discipline

- Account for existing rows, nullability, defaults, lock duration, transaction size, index build behavior, replication lag, and failure recovery.
- Prefer expand-and-contract when old and new application versions can overlap.
- Make data work resumable and observable when it cannot complete safely in one bounded transaction.
- Distinguish rollback from roll-forward. Do not promise rollback after destructive or lossy transformation without a verified recovery source.
- Verify application compatibility, data invariants, performance-sensitive paths, and post-deploy cleanup conditions.
- Do not run production migrations or destructive cleanup without explicit authorization and a resolved target.

## Handoff

Return: affected data and consumers, rollout phases, compatibility window, lock/performance risks, recovery strategy, verification queries or tests, monitoring signals, and cleanup gate.
