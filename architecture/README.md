# Architecture baseline

The implementation adopts the Actualis Stack Architecture Vision v0.1 boundaries as its starting
hypothesis. The repository prioritizes Actualis Core and also hosts a separately owned
manufacturing reference application that proves the Core seam plus a Phase 0 Stock domain
application that currently defines contracts only.

## Current programme baseline

- [Architecture Baseline v0.2](BASELINE_V0.2.md) reconciles the original stack vision with
  accepted repository decisions, current implementation evidence, open decisions, and delivery
  gates.
- [Manufacturing exception and replan reality contract
  v0.1](reality-contracts/manufacturing-exception-replan-v0.1.md) defines the selected first
  cross-component proof journey and the evidence required before it is considered validated.
- [Phase 0 reality-contract evidence gate](phase-0/README.md) records prepared artifacts, external
  blockers, and the evidence still required before Phase 1 claims are accepted.

## Core versus adjacent components

| Core owns | Adjacent component owns |
| --- | --- |
| Cell context, principal links, relationships, purposes, policy decisions | Identity-provider credentials and login UX |
| Governed capability invocation and effect coordination | HTTP, websocket, webhook, JSON-RPC, MCP, or industrial wire adapters |
| Commitment, calendar, intent, scenario, decision, and execution envelopes | Domain-specific schedules, routings, curricula, materials, students, or products |
| Evidence graph, provenance, audit metadata, retention class | Raw telemetry payloads and domain evidence content |
| Transactional outbox/inbox and delivery requests | Relay providers, Signal ingest, Edge transport, solver workers, AI workers, and Surface projections |
| Stable contracts and conformance tests | Product-specific experiences and domain invariants |

## Executable application boundary

The current umbrella dependency direction is:

```text
actualis_stock  ------>  actualis_core  <-----  actualis_manufacturing
                              ^                         ^
                              +-------- actualis_web ---+
```

- `actualis_core` has no compile-time dependency on Stock or manufacturing and does not interpret
  product payloads or query product tables.
- `actualis_manufacturing` implements the Core capability-handler contract and owns pallet
  schemas, invariants, events, projections, seeds, tests, and future migrations.
- `actualis_stock` currently owns its organisation scope, capability vocabulary, and future module
  boundary; it registers no handler and owns no table in Phase 0.
- `actualis_web` is currently an adapter over Core and manufacturing; it has no Stock dependency
  or route in Phase 0.

The applications are modules in one deployable umbrella, not separate services. Core opens the
repository transaction and calls the product handler in-process so domain effects, receipt,
evidence, and durable delivery intent remain atomic.

## Accepted baseline

1. Core is a capability-centric modular monolith.
2. Each cell is a unit of authority, isolation, scaling, and recovery with one fenced PostgreSQL writer.
3. Every consequential invocation carries cell, principal, purpose, context, risk, idempotency, expected version, and contract version.
4. Authorization combines capability, relationship, attributes, purpose, context, risk, field policy, and obligations.
5. Domain packages own concrete business schemas and invariants; Core never creates a universal entity table.
6. Observation, inference, decision, command, and evidence remain distinct contracts.
7. Externally visible changes use versioned events written through a transactional outbox.
8. Evidence is durable and reconstructable; derived projections are replaceable.
9. Wire protocols and provider integrations are adapters around Core ports.
10. Extraction into services occurs only after an independent resource, security, availability, network, or cadence requirement is demonstrated.
11. Core authorization never substitutes for local, safety-rated, or physical protection; a lower safety layer may always inhibit an operation.
12. Replay and simulation use explicit versioned inputs, recorded nondeterministic results, and isolated state; neither may silently repeat production side effects.

## Internal modules

- Cell Runtime: cell placement context, data boundary, configuration version, and workload identity.
- Identity and Authority: principal links, relationships, purposes, grants, policy versions, decisions, and obligations.
- Capability Runtime: contract registry, invocation pipeline, idempotency, expected version, effect coordination, and safe errors.
- Commitments and Calendars: generic obligation/reservation envelopes, lifecycle, effective time, and domain references.
- Decision and Scenario: intent, snapshot reference, candidates, selection, explanation reference, and approval state; no solver implementation.
- Execution: command envelope, dispatch state, acknowledgement, expiry, compensation reference, and durable coordination.
- Evidence: provenance graph, hashes, object references, retention class, audit reconstruction, and integrity status.
- Delivery Port: transactional outbox/inbox, communication requests, and versioned events; no provider or wire adapter.

Modules do not read or write another module's tables directly. Typed in-process calls preserve local transactions. A strict dependency graph and conformance tests make the seams executable.

## Technology starting point

- Elixir and Phoenix for the Core runtime and operational API host.
- PostgreSQL for authoritative module schemas, policy state, coordination, evidence metadata, and outbox/inbox.
- S3-compatible evidence port for durable payloads, with PostgreSQL storing hashes and metadata.
- External OIDC through a replaceable principal-resolution port.
- OpenTelemetry-compatible traces and metrics keyed by cell, capability, principal type, policy version, and evidence ID.

No TypeScript UI, Rust edge agent, solver, telemetry store, or provider adapter is required to implement Core itself.

## ADRs

- [ADR 0001](adr/0001-capability-centric-modular-monolith.md)
- [ADR 0002](adr/0002-single-cell-postgresql-authority.md)
- [ADR 0003](adr/0003-domain-packages-outside-core.md)
- [ADR 0004](adr/0004-safety-and-operational-authority-boundary.md)
- [ADR 0005](adr/0005-deterministic-replay-and-simulation-contract.md)
- [ADR 0006](adr/0006-pallet-movement-application-module.md)
- [ADR 0007](adr/0007-manufacturing-exception-replan-lead-proof-journey.md)

### Domain package decisions

- [Stock ADR 0001](../apps/actualis_stock/architecture/adr/0001-stock-domain-package-foundation.md)
