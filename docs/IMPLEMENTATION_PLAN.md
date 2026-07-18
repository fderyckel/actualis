# Actualis Core implementation plan

## Outcome

Within the first 90 days, deliver a production-shaped, single-cell Actualis Core runtime that a separate domain package can integrate without bypassing authority, transactions, evidence, or delivery guarantees.

This plan implements the Core architecture only. It does not implement the manufacturing, education, or commerce proof slices from the wider Actualis Stack plan.

## Definition of Core

Core is the stable runtime for:

1. Cell and principal context
2. Governed capability invocation
3. Fine-grained authorization and obligations
4. Commitment and calendar lifecycle
5. Intent, scenario, decision, selection, and approval metadata
6. Command execution, acknowledgement, and durable coordination
7. Evidence, provenance, and audit reconstruction
8. Transactional outbox/inbox and ports to adjacent components

Core does not own concrete operational entities or invariants. A teacher, learner, pallet, machine, work order, course, room, catalog item, or payment is always domain-owned.

## Core v0 scope

### Build now

- One routable cell and one fenced PostgreSQL writer.
- OIDC principal-resolution port plus deterministic test identities.
- Human, device, integration, worker, support, and AI principal types.
- Versioned capability registry and invocation pipeline.
- Policy decision contract with relationships, attributes, purpose, context, risk, fields, obligations, and safe explanations.
- Idempotency ledger, expected-version behavior, transactional effect collector, and safe retry rules.
- Commitment/calendar, scenario/decision, execution, and evidence envelopes with governed lifecycle transitions.
- Transactional outbox/inbox and bounded durable workers.
- S3-compatible evidence port with hashes, retention metadata, and integrity checks.
- Authorized audit reconstruction.
- Domain-package conformance kit and test fixture with a separate schema.
- Disposable cell template, CI gates, observability, migration rehearsal, backup, and restore.

### Define ports but do not implement adjacent products

- Surface projections and sync
- Edge observations and commands
- Signal telemetry promotion
- Decide solver requests/results/explanations
- Guide AI/insight requests
- Relay communication delivery
- Link HTTP, websocket, webhook, RPC, MCP, and broker adapters

Core emits or accepts typed envelopes at these boundaries. The adjacent component owns transport, scaling, and product behavior.

### Defer deliberately

- Any manufacturing, education, commerce, or other domain model
- Product experiences and client SDK
- Generic schema/capability compiler or universal entity store
- Raw telemetry storage, solvers, runtime AI, and provider delivery
- NATS, Temporal, ClickHouse, OpenSearch, graph/vector databases, and Kubernetes
- Multi-cell control plane, global writes, cross-region disaster recovery, and production support console

## Target architecture

The first runtime is one Phoenix deployment with explicit internal modules and one PostgreSQL database containing module-owned schemas. Typed in-process contracts keep important transactions local. Externally visible changes use a versioned transactional outbox.

```text
             adapters and adjacent components
                          |
                 Core public contracts
                          |
              Capability Runtime pipeline
      cell -> principal -> policy -> handler -> effects
         |          |          |          |          |
    Cell Runtime  Authority  Domain port  Evidence  Outbox
                                   |
                     external domain package schema
```

Repository shape introduced as artifacts arrive:

```text
/architecture       ADRs, threat models, dependency rules, quality scenarios
/contracts/core     canonical Core envelopes and compatibility fixtures
/kernel             Phoenix runtime and module-owned schemas
/conformance        domain-package test kit and non-product fixture
/evals               policy, idempotency, concurrency, replay, and load cases
/deployment         cell template, migrations, runbooks, SLOs, and restore tools
```

No `/modules/manufacturing`, `/modules/education`, `/experiences`, `/edge`, `/signal`, `/decide`, `/guide`, `/relay`, or `/link` implementation belongs in this repository.

## Twelve-week delivery plan

### Weeks 1-2: freeze Core boundaries and contracts

Deliverables:

- Context map showing Core and every adjacent component.
- Module dependency graph and schema ownership rules.
- Canonical envelopes for cell, principal, capability, policy, obligation, commitment, scenario, decision, execution, evidence, event, outbox, and inbox.
- Error taxonomy, compatibility rules, lifecycle state machines, and temporality policy.
- Threat model for cell scope, support/break-glass, policy administration, replay, object evidence, and adapter trust.
- Quality scenarios, initial SLOs, and data classification/retention map.

Exit gate: every Core concept has an owner and every domain concept is explicitly outside the kernel.

### Weeks 3-4: scaffold the cell runtime

Deliverables:

- Phoenix/PostgreSQL project with module-boundary checks and module-owned migration paths.
- Cell context, configuration version, request correlation, workload identity, and bounded pool configuration.
- OIDC principal-resolution port with deterministic human/device/integration/worker/AI test principals.
- Reproducible local cell, synthetic fixtures, structured logs, traces, metrics, and health/readiness semantics.
- CI for formatting, tests, dependency/secret scanning, migration validation, SBOM, and artifact digest.

Exit gate: a request resolves one cell and principal through public Core contracts with no domain schema present.

### Weeks 5-6: capability and authority runtime

Deliverables:

- Versioned capability descriptor and registration API.
- Invocation envelope validation and ordered policy pipeline.
- Relationship, purpose, attribute, context, risk, field, and obligation evaluation.
- Default deny, safe reason codes, policy versioning, delegation, support grant, break-glass, and separation-of-duties behavior.
- Idempotency ledger, expected-version contract, concurrency control, and deterministic result replay.
- Conformance fixture invoking a domain-owned handler in a separate schema.

Exit gate: the fixture proves allow, deny, allow-with-obligations, stale-version, duplicate, cross-cell, and self-approval behavior without adding domain semantics to Core.

### Weeks 7-8: commitments, decisions, and execution

Deliverables:

- Commitment and calendar envelopes with proposed-to-verified lifecycle and effective-time rules.
- Intent, scenario snapshot reference, candidate, selection, explanation reference, approval, and decision records.
- Execution command, dispatch, expiry, acknowledgement, compensation reference, and durable job state.
- Transaction boundary that atomically combines domain effects with Core lifecycle transitions when required.
- Invalid-transition, approval, conflict, expiry, and retry tests.

Exit gate: no proposal becomes a commitment and no decision becomes execution without the declared authority, versions, and evidence.

### Weeks 9-10: evidence and transactional delivery seams

Deliverables:

- Evidence metadata, content hash, provenance links, retention class, legal-hold hook, and integrity status.
- S3-compatible evidence port and deterministic local implementation.
- Authorized audit reconstruction across Core module interfaces.
- Transactional outbox/inbox, retry state, deduplication, dead-letter state, and redrive contract.
- Typed ports for Domain Events, Surface, Edge, Signal, Decide, Guide, Relay, and Link without implementing those components.
- Conformance tests proving a restarted worker or duplicate delivery cannot duplicate an authoritative effect.

Exit gate: one fixture invocation can be reconstructed from principal and policy through domain reference, effects, evidence, and delivery state.

### Weeks 11-12: hardening and integration readiness

Deliverables:

- Disposable cell from a versioned template with synthetic principals, policies, and the conformance fixture.
- Immutable artifact promotion through test and production-shaped pre-production.
- Expand/migrate/contract rehearsal, backup restore, object-integrity reconciliation, worker loss, queue backlog, and database failover exercises.
- Load report for capability throughput, policy evaluation, outbox lag, connection-pool isolation, and audit queries.
- Published Core conformance kit, integration guide, updated ADRs, measured bottlenecks, and go/revise recommendation.

Exit gate: a separately packaged domain fixture integrates only through supported Core contracts and all relevant quality gates pass.

## Workstreams and ownership

| Workstream | Owns | First proof |
| --- | --- | --- |
| Cell Runtime | cell scope, configuration, pools, lifecycle | isolated single-cell request and recovery |
| Identity and Authority | principals, relationships, policy, obligations | explained allow/deny with policy version |
| Capability Runtime | registration, invocation, idempotency, transaction | one governed handler invocation with deterministic replay |
| Commitments and Decisions | lifecycle, temporality, approval | invalid transitions and self-approval cannot commit |
| Execution | dispatch, acknowledgement, expiry, durable work | restart-safe command lifecycle |
| Evidence | provenance, hashes, retention, audit | complete authorized reconstruction |
| Delivery Port | outbox/inbox and adjacent contracts | duplicate-safe post-commit delivery |
| Platform Reliability and Security | CI, SLOs, migrations, restore, threats | immutable promotion and recovery evidence |

Recommended initial team: one Core architecture/domain-model lead, three Core engineers split across authority, lifecycle, and evidence/delivery, and one platform/security engineer. Privacy/security and a representative from at least one domain-package team review contracts throughout. A smaller team should extend the schedule or reduce contract breadth rather than collapse module boundaries.

## Initial backlog

### Epic A: boundaries and contracts

- Context map and dependency graph
- Core envelope schemas and compatibility rules
- Lifecycle state machines and temporality rules
- Threat model and quality scenarios

### Epic B: cell, identity, and authority

- Cell/request context and principal mapping
- Relationship/purpose/context policy
- Obligations, explanations, delegation, and support access
- Default-deny and cross-cell tests

### Epic C: capability runtime

- Registry and version resolution
- Invocation validation and handler port
- Idempotency, expected version, transaction/effect collector
- Conformance fixture and kit

### Epic D: commitments, decisions, and execution

- Commitment/calendar envelope
- Scenario/decision/approval envelope
- Dispatch/acknowledgement/expiry/compensation lifecycle
- Effective-date, concurrency, and recovery tests

### Epic E: evidence and delivery

- Evidence graph, object port, integrity, retention
- Audit reconstruction
- Outbox/inbox, retry, dead-letter, and redrive
- Adjacent-component port contracts

### Epic F: delivery and operations

- Reproducible build and SBOM
- Disposable cell template
- Immutable promotion
- Migration, restore, load, isolation, and failure exercises

## Day-90 definition of success

- A separately packaged conformance domain registers and invokes a capability without direct access to Core tables.
- Human, device, integration, worker, support, and AI principal types use the same governed authorization contract.
- Allow, deny, obligation, idempotency, stale-version, cross-cell, delegation, and separation-of-duties cases are reproducible.
- Commitment, decision, approval, execution, acknowledgement, and evidence lifecycles are explicit and cannot be skipped.
- Domain effects, Core evidence, and outbox entries commit atomically where required.
- Worker restart, duplicate delivery, and redrive do not duplicate authoritative effects.
- An authorized audit reconstructs the full invocation without cross-module SQL.
- One immutable artifact promotes to pre-production and restores with evidence integrity intact.
- Interactive capability work retains its SLO while background delivery saturates its bounded pool.
- Core contains no manufacturing, education, commerce, experience, device-protocol, telemetry, solver, AI-task, or provider semantics.

## Gate before wider stack implementation

Core can be called integration-ready after these tests, but the Actualis Stack is not proven until at least one real domain package and product journey validate the contracts. That validation must happen outside this repository. If a domain team needs to add business entities to Core, pause and review whether the Core envelope is genuinely incomplete or the domain boundary is wrong.
