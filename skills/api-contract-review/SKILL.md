---
name: api-contract-review
description: Assess changes to externally or internally consumed API contracts, schemas, events, webhooks, generated clients, and DTO boundaries. Use when compatibility, versioning, consumer impact, idempotency, or rollout order may matter. Do not use for purely internal refactors that preserve every observable contract.
---

# API contract review

Determine whether a proposed or implemented contract change is safe for known consumers and deployment realities.

## Establish the contract surface

1. Locate the source of truth, generated artifacts, producers, consumers, adapters, tests, and deployment boundaries.
2. Classify the contract: synchronous API, asynchronous event/message, webhook, file/schema exchange, or internal service boundary.
3. Identify observable behavior: names, types, nullability, defaults, validation, ordering, pagination, errors, authentication, authorization, retries, and timing guarantees.
4. Read only the matching reference:
   - HTTP/RPC/GraphQL or generated clients: [references/request-response.md](references/request-response.md)
   - Events, queues, streams, or webhooks: [references/events-webhooks.md](references/events-webhooks.md)

## Review the change

- Compare old and new behavior from each consumer's perspective.
- Separate additive changes from breaking semantic changes; a schema-compatible change can still break behavior.
- Identify mixed-version windows and required producer/consumer rollout order.
- Check idempotency, retries, duplicate delivery, partial failure, and error compatibility where relevant.
- Confirm documentation, examples, fixtures, contract tests, and generated clients remain aligned.
- Prefer expand-and-contract or versioned transitions when atomic deployment cannot be guaranteed.
- Do not infer permission to publish, deploy, or regenerate external artifacts.

## Handoff

Return: contract surface, known consumers, compatibility classification, rollout constraints, required tests, migration or deprecation plan, and unresolved consumer assumptions.
