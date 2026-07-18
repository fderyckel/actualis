# Core runtime skeleton

## Goal

Prove the complete Actualis Core lifecycle without embedding manufacturing, education, commerce, UI, device, solver, or provider semantics in the kernel.

## Conformance fixture

Tests use a deliberately minimal external domain fixture. It declares a typed capability and owns a small transactional aggregate in its own schema. The fixture can return:

- success with authoritative effects and a versioned domain event;
- domain-invariant rejection;
- stale-version rejection;
- a request for an approval or evidence obligation;
- a retryable or permanent failure.

Core treats the command payload, aggregate, invariant, and domain event as domain-owned types. It verifies orchestration, not the business rule.

## Runtime path

1. An adapter supplies a cell context, authenticated principal reference, purpose, capability/version, request context, idempotency key, expected version, and typed command.
2. Cell Runtime rejects invalid placement or cross-cell scope.
3. Identity and Authority resolve principal relationships and evaluate the effective policy.
4. Capability Runtime returns deny, allow, or allow-with-obligations using stable safe reason codes.
5. On allow, the registered domain handler runs inside a controlled PostgreSQL unit of work and remains responsible for its invariant and state mutation.
6. Core atomically records the invocation outcome, authorization decision, obligations, evidence links, and outbox effects with the domain transaction.
7. Post-commit workers expose versioned events and delivery requests through Core ports with bounded retries and idempotency.
8. Execution records dispatch, acknowledgement, expiry, and compensation references when a capability creates durable work.
9. An authorized audit query reconstructs cell, principal, purpose, policy, capability, domain reference, effects, deliveries, and evidence.

## Minimum Core contracts

- `CellContext`
- `PrincipalContext`
- `CapabilityDescriptor`
- `InvocationEnvelope`
- `AuthorizationRequest` and `AuthorizationDecision`
- `Obligation`
- `DomainHandler` and transactional `EffectSet`
- `CommitmentEnvelope` and lifecycle transition
- `ScenarioEnvelope`, `DecisionRecord`, and selection/approval transition
- `ExecutionCommand`, `DispatchRecord`, and `Acknowledgement`
- `EvidenceRef`, `ProvenanceLink`, and `AuditRecord`
- `DomainEventEnvelope`, `OutboxRecord`, and `InboxReceipt`
- `CommunicationRequest` port

These are stable semantic envelopes, not generic tables for every business entity.

## Minimum authoritative records

- cell configuration/version and workload identity;
- principal link, relationship, purpose, grant, policy version, and decision;
- capability registration, invocation, idempotency result, and expected version;
- commitment, scenario, decision, approval, execution, and acknowledgement envelopes;
- evidence metadata, hash, retention class, provenance link, and integrity state;
- outbox record, inbox receipt, retry state, and delivery request.

Domain fixture records stay in a separate schema and are not queried directly by Core modules.

## Definition of done

- Human, device, integration, worker, and AI principal types traverse the same authorization contract.
- Allow, deny, redact/limit, require-approval, step-up, rate-limit, log, and expiry obligations are representable and reproducible.
- Duplicate invocations return the recorded result without a second domain effect.
- A stale expected version rejects without silent overwrite.
- Cross-cell, wrong-purpose, expired-relationship, self-grant, and self-approval cases deny safely.
- Domain effects, Core evidence, and outbox records commit atomically or not at all.
- Worker restart and duplicate delivery preserve at-least-once delivery without duplicate authoritative effects.
- Commitment and decision lifecycle transitions cannot skip required authority or approval.
- The audit view reconstructs a consequential invocation without cross-module table access.
- A separate conformance package integrates without adding a domain entity or field to Core.
- Backup restore, migration rehearsal, workload isolation, and immutable promotion pass their declared targets.

## Stop rules

- Do not add a manufacturing, education, commerce, or generic business entity to Core.
- Do not turn opaque domain references into an entity/attribute store.
- Do not implement a generic schema compiler before repeated Core contracts justify it.
- Do not add Link, Relay provider, Surface, Edge, Signal, Decide worker, or Guide behavior to make the Core demo look complete.
- Do not let adapters, background jobs, support tools, or AI bypass the capability and authorization pipeline.
