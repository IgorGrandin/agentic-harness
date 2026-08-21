# Request-response contracts

Review the protocol and the repository's actual contract source of truth.

## Compatibility lenses

- route or method identity, operation names, headers, media types, and authentication;
- request names, types, nullability, defaults, validation, and unknown-field handling;
- response names, types, optionality, enum evolution, ordering, pagination, and timestamps;
- status codes, error bodies, error identifiers, retry hints, and rate-limit behavior;
- GraphQL nullability, argument changes, field deprecation, unions, interfaces, and persisted operations;
- generated-client regeneration, serialization settings, and language-specific breaking changes.

An additive field is not automatically safe: strict deserializers, exhaustive enum switches, validation, caching, signatures, and payload-size limits may still break consumers.

## Transition

When producer and consumer cannot deploy atomically:

1. expand the contract so old and new consumers both work;
2. deploy tolerant readers before new writers where possible;
3. observe adoption and failures;
4. deprecate with an explicit window;
5. contract only after evidence shows old usage is gone.

Define contract tests at the boundary and end-to-end verification for semantics that schemas cannot express.
