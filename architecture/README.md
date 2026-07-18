# Architecture baseline

The implementation adopts the Actualis Stack Architecture Vision v0.1 boundaries as its starting hypothesis and narrows this repository to Actualis Core.

## Core versus adjacent components

| Core owns | Adjacent component owns |
| --- | --- |
| Cell context, principal links, relationships, purposes, policy decisions | Identity-provider credentials and login UX |
| Governed capability invocation and effect coordination | HTTP, websocket, webhook, JSON-RPC, MCP, or industrial wire adapters |
| Commitment, calendar, intent, scenario, decision, and execution envelopes | Domain-specific schedules, routings, curricula, materials, students, or products |
| Evidence graph, provenance, audit metadata, retention class | Raw telemetry payloads and domain evidence content |
| Transactional outbox/inbox and delivery requests | Relay providers, Signal ingest, Edge transport, solver workers, AI workers, and Surface projections |
| Stable contracts and conformance tests | Product-specific experiences and domain invariants |

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
