# Schema rollout

Evaluate engine-specific behavior from authoritative documentation when lock, rewrite, online-index, or transaction semantics can affect production.

## Expansion

- add new nullable or compatible structures without breaking old code;
- create indexes using the safest supported strategy for the engine and load profile;
- deploy readers and writers that tolerate both old and new representations;
- avoid volatile defaults or full-table rewrites unless their cost is understood.

## Transition

- dual-read or dual-write only with explicit precedence and reconciliation rules;
- validate constraints separately when the engine supports a safer staged path;
- observe error rates, lock waits, replication lag, and query plans;
- keep mixed-version behavior explicit.

## Contraction

- prove old readers and writers are gone before removing compatibility;
- verify data completeness before making constraints stricter;
- separate destructive cleanup from the release that stops usage when possible;
- retain a recovery source for lossy operations or declare roll-forward as the recovery strategy.

Record execution order, expected duration, lock scope, abort condition, and cleanup gate. Generated migration output must be reviewed; framework success does not prove operational safety.
