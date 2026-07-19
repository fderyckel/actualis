# Quality gates for Actualis Core

These gates operationalize the accepted architecture decisions, including
[ADR 0004](../architecture/adr/0004-safety-and-operational-authority-boundary.md) and
[ADR 0005](../architecture/adr/0005-deterministic-replay-and-simulation-contract.md).

## Boundary

- Core contains no manufacturing, education, commerce, UI, device-protocol, telemetry, solver, AI-task, or provider schema.
- The module dependency graph is checked automatically.
- Modules cannot read or write another module's tables directly.
- The conformance fixture integrates through public Core contracts only.

## Contract

- Core envelopes are versioned and have backward/forward compatibility fixtures.
- A capability version is immutable after publication.
- Domain handler, event, evidence, commitment, decision, execution, and delivery ports have consumer conformance tests.
- Safe errors and reason codes cannot reveal protected resources or policy details.

## Capability and transaction

- Cell, principal, purpose, context, risk, idempotency key, expected version, and contract version are required where applicable.
- Duplicate idempotency keys return the recorded result.
- Stale expected versions reject without overwrite.
- Concurrent invocations cannot both violate a domain aggregate version.
- Domain effect, authorization result, evidence links, and outbox record commit atomically.

## Safety and operational authority

- A capability authorization is permission to attempt an operation through the next enforcement boundary; it is never represented as proof of physical safety or execution.
- A lower physical, safety-rated, device, or Edge enforcement layer can inhibit an operation and no higher-layer principal or grant can override it.
- Safety-relevant contracts declare criticality, freshness, expiry, expected state, acknowledgement, and fail-safe behavior where applicable.
- Expired, stale, payload-mismatched, or context-mismatched commands reject before a new authoritative effect is committed. An identical idempotent retry returns or acknowledges the recorded outcome without repeating the effect.
- Disconnected operation is denied by default. Any bounded offline authority names its scope, duration, local invariants, reconciliation behavior, and recovery test.
- Signatures and hardware-backed attestation are treated as evidence of identity, origin, integrity, or measured device state, not as proof that a physical observation is true.
- Domain packages own concrete safety invariants and certification evidence; Core conformance tests verify only the declared Core envelope and enforcement semantics.

## Authority and privacy

- Tests cover principal x relationship x purpose x attribute x context x risk x cell.
- New capabilities, fields, principal types, and relationships deny by default.
- Cross-cell, support-access, delegation, break-glass, self-grant, and self-approval negative tests are mandatory.
- Every allow, deny, field decision, and obligation records policy version and a safe reason code.
- High-risk decisions are never served from a stale authorization cache.

## Commitments, decisions, and execution

- Proposed, selected, approved, committed, dispatched, executed, and verified states remain distinct.
- Invalid lifecycle transitions and missing approvals reject deterministically.
- Effective-dated and bitemporal behavior is used only when the declared invariant requires it.
- Dispatch has expiry, expected state, risk class, acknowledgement, and compensation references.

## Evidence and delivery

- Principal, purpose, policy, capability, input provenance, effects, versions, and outcome are linked.
- Observation evidence preserves source, observation time, ingestion time, assurance or calibration references, confidence, and validation status when those fields are supplied by the owning domain.
- Object hashes, retention metadata, and evidence links survive backup and restore.
- Outbox and inbox processing are at-least-once and idempotent.
- Adjacent systems cannot write authoritative Core or domain tables directly.
- Audit reconstruction uses authorized module interfaces rather than cross-schema queries.

## Deterministic replay and simulation

- Replay identifies an explicit input set: snapshot or starting versions, ordered records, contract and policy versions, configuration, clock values, generated identifiers, randomness inputs, and recorded external results where applicable.
- Capability and policy evaluation cannot depend on unrecorded wall time, randomness, process state, environment state, or network results.
- Historical replay returns recorded external, device, solver, and AI results by default; it does not silently invoke them again.
- Replaying a completed invocation cannot repeat an authoritative effect, publish a new outbox event, or dispatch an external side effect.
- A simulation uses an isolated namespace and disabled production delivery ports. Negative tests prove that simulated state cannot mutate authoritative tables or enter a production outbox.
- Replay and simulation results declare their determinism scope, substituted inputs, and any unsupported historical version.
- Retained contracts and evidence have a tested replay path for the declared retention period or an explicit, reviewable incompatibility record.

## Performance and isolation

Initial hypotheses from the architecture vision:

- ordinary online capability: p95 below 250 ms and p99 below 750 ms, excluding external providers, solvers, and AI;
- post-commit event availability: p95 below 1 second within a region;
- interactive capability work retains its SLO while durable jobs or delivery workers saturate their bounded pools;
- reconnect or adapter storms apply backpressure without exhausting the command database pool.

Test inputs must include realistic relationship and policy evaluation, not only a health endpoint.

## Security and supply chain

- Dependency, secret, and static analysis checks run in CI.
- The build produces an SBOM, provenance, and immutable artifact digest.
- Cross-cell leakage, support compromise, replay, policy expansion, and evidence tampering have executable regression tests.
- No critical finding is open at release; accepted high risks name an owner and expiry.

## Operations

- One command creates a disposable cell with synthetic principals, policies, and conformance fixtures.
- The same artifact digest promotes through test and pre-production.
- PostgreSQL backup restores into an isolated verification cell with count/hash reconciliation.
- Migration lock time, replication impact, worker loss, queue backlog, database failover, and object-store outage are exercised.
- Every component has an owner, failure mode, SLO, alert, recovery procedure, and exit path.
