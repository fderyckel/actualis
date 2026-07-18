# ADR 0001: Capability-centric modular monolith

- Status: Accepted baseline
- Date: 2026-07-18

## Context

Actualis must preserve domain transactions, explainability, and developer speed while keeping replaceable boundaries. Premature service extraction would add network and operational failure modes before workload evidence exists.

## Decision

Build the first production core as a capability-centric modular monolith. Each module owns its schema, invariants, policies, and capabilities. Cross-module work uses typed in-process contracts; externally visible facts use versioned events.

Every consequential command passes through one capability boundary that evaluates principal, purpose, relationship, context, risk, expected version, idempotency, invariants, effects, and evidence.

## Consequences

- Important transactions remain local and debuggable.
- Module ownership must be tested and enforced in code review and static checks.
- A module becomes separately deployable only after an independent resource, security, availability, network-placement, or release-cadence need is demonstrated.
- Generic CRUD endpoints may exist for diagnostics but cannot bypass governed capabilities.
