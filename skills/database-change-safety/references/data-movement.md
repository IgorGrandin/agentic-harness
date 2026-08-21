# Data movement and backfills

Treat a large transformation as an observable, resumable process rather than one opaque transaction.

## Design

- define source-of-truth, target invariant, selection predicate, and deterministic transformation;
- choose stable batching and checkpoint keys;
- make reruns idempotent or detect completed units safely;
- bound transaction size, lock time, memory, and write amplification;
- account for concurrent writes and specify reconciliation or cutover behavior.

## Operate

- expose progress, throughput, failures, retries, and remaining work;
- throttle from measured database health rather than a fixed optimistic rate;
- use bounded retries and isolate poison records for investigation;
- define pause, resume, abort, and ownership procedures;
- avoid logging sensitive row contents.

## Verify

- compare counts only as a first signal, not proof of semantic correctness;
- check invariants, representative samples, nulls, duplicates, orphaned relations, and boundary values;
- reconcile writes that occurred during the backfill;
- define the evidence required before switching reads or deleting old data.

State whether recovery is rollback, restoration from a verified source, or corrective roll-forward.
