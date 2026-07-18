# ADR 0003: Domain packages remain outside Actualis Core

- Status: Accepted baseline
- Date: 2026-07-18

## Context

Actualis Core must provide reusable authority, commitment, decision, execution, and evidence behavior without turning manufacturing, education, or commerce concepts into a universal model.

## Decision

Domain packages remain outside the Core repository and own:

- their relational schemas and migrations;
- business entities and effective-time rules;
- domain invariants and capability handlers;
- domain events, projections, and product-specific evidence content.

Core owns governed invocation and stable envelopes. It may store typed domain references and opaque versioned payload references where a Core lifecycle requires them, but it must not interpret domain fields or offer generic entity/attribute persistence.

A minimal conformance fixture may live under test/evaluation code. It exists only to prove Core behavior and is never presented as a manufacturing, education, or commerce module.

## Consequences

- Core can evolve around stable behavioral contracts rather than a shared ontology.
- A domain package integrates through declared capability, policy, transaction, event, and evidence ports.
- A real product slice is still required to validate usefulness, but its implementation and roadmap remain separate.
- Any proposal to add a domain field or entity to Core requires a new ADR proving that the concept is a stable Core lifecycle envelope rather than product semantics.
