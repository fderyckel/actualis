# Quality gates for Actualis Core

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
- Object hashes, retention metadata, and evidence links survive backup and restore.
- Outbox and inbox processing are at-least-once and idempotent.
- Adjacent systems cannot write authoritative Core or domain tables directly.
- Audit reconstruction uses authorized module interfaces rather than cross-schema queries.

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
