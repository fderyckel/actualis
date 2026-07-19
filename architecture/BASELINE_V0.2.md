# Actualis Architecture Baseline v0.2

- Status: Accepted working baseline
- Decision date: 2026-07-19
- Scope: Actualis Core and the first cross-component proof journey
- Upstream vision: [Actualis Stack Architecture Vision v0.1](../docs/Actualis_Stack_Architecture_Vision_v0.1.pdf)
- Delivery plan: [Actualis Core implementation plan](../docs/IMPLEMENTATION_PLAN.md)

## Purpose

This baseline reconciles the 50-page Actualis Stack Architecture Vision v0.1 with the
decisions and executable evidence now present in the repository.

It does not claim that the wider stack is implemented. It records:

- which v0.1 decisions remain accepted;
- which decisions have been refined by repository ADRs;
- which hypotheses remain unproven;
- the first product journey that must validate Core; and
- the order in which conflicting architecture material is interpreted.

## Authority order

When architecture material conflicts, use this order:

1. Executable behavior and tests describe what currently exists.
2. Accepted repository ADRs define current architectural decisions.
3. This v0.2 baseline reconciles those decisions into one programme-level view.
4. The Core implementation plan and quality gates define planned delivery evidence.
5. The v0.1 PDF remains the upstream product and stack vision.

Changed evidence must produce an ADR or a new baseline version. It must not create an
undocumented exception.

## What changed since v0.1

### Core is narrower

The v0.1 paper described the whole Actualis Stack. The current repository is deliberately
limited to Actualis Core. Domain packages, product surfaces, Edge, Signal, Decide, Guide,
Relay, and Link are adjacent consumers of Core contracts, not Core modules.

### Manufacturing is a proof consumer, not kernel vocabulary

The pallet-movement proof now lives in a separate `actualis_manufacturing` umbrella application.
[ADR 0006](adr/0006-pallet-movement-application-module.md) records its ownership. Manufacturing
schemas, invariants, events, and projections sit behind declared Core ports while remaining
co-deployed so authoritative effects can share one database transaction.

### Operational authorization is not physical-safety authority

[ADR 0004](adr/0004-safety-and-operational-authority-boundary.md) makes the enforcement
order explicit. Core may authorize an attempt. Local safety controls and physical protection
may still inhibit it, and Core cannot override them.

### Deterministic replay precedes simulation

[ADR 0005](adr/0005-deterministic-replay-and-simulation-contract.md) requires explicit
clocks, identifiers, versions, and recorded external results. Historical reconstruction must
not silently repeat an authoritative or external effect.

### The first proof journey is selected

[ADR 0007](adr/0007-manufacturing-exception-replan-lead-proof-journey.md) selects the
manufacturing exception and replan journey as the first cross-component proof. This choice
uses the current pallet work without making manufacturing part of Core.

## Reconciled decision register

| v0.1 decision | v0.2 disposition | Canonical evidence or next proof |
| --- | --- | --- |
| 0001 Capability-centric modular monolith | Accepted | [ADR 0001](adr/0001-capability-centric-modular-monolith.md) |
| 0002 Independent experience packages | Accepted stack boundary; unimplemented | Two distinct surfaces in the first reality contract |
| 0003 Data-class ownership over database neutrality | Accepted | [ADR 0002](adr/0002-single-cell-postgresql-authority.md) and [ADR 0003](adr/0003-domain-packages-outside-core.md) |
| 0004 Cell as placement, scale, and recovery unit | Accepted; implementation planned | Single-cell conformance and restore proof |
| 0005 Observation, inference, decision, and command remain distinct | Accepted; partial contract only | Observation promotion and decision evidence in the first reality contract |
| 0006 AI is a governed principal, never authority | Accepted boundary; runtime AI deferred | Principal and authorization conformance without an AI product |
| 0007 Solver portfolio behind a typed decision contract | Accepted boundary; solver choice deferred | First replan problem definition and measured explanation needs |
| 0008 Selective temporality | Accepted | Contract-level effective-time rules before lifecycle persistence |
| 0009 Fine-grained authorization is first-class | Accepted; partial implementation | Authority matrix and negative conformance tests |
| 0010 PostgreSQL outbox and native durable execution first | Accepted starting mechanism; publisher absent | Restart, duplicate, dead-letter, and redrive proof |
| 0011 ClickHouse telemetry candidate | Proposed and deferred | Site-shaped benchmark; raw telemetry stays outside the command database |
| 0012 Immutable artifact promotion | Accepted; unimplemented | Same digest promoted through sandbox, test, pre-production, and canary |
| 0013 Tiered redundancy and one fenced writer per cell | Accepted | [ADR 0002](adr/0002-single-cell-postgresql-authority.md) plus restore and failover evidence |
| 0014 Protocols are adapters around canonical contracts | Accepted; unimplemented | Signed webhook and one second adapter through shared conformance |

## Current implementation truth

The repository currently provides a partial proof:

- one Phoenix and PostgreSQL umbrella runtime with separate Core, manufacturing, and web
  applications;
- a configured domain-neutral capability registry, handler port, command envelope, and delivery
  port;
- a manufacturing pallet-movement handler that consumes those Core ports;
- human, device, assignment, grant, and policy checks;
- principal-scoped idempotency and deterministic request hashing;
- expected-version and row-lock concurrency protection;
- atomic movement, receipt, evidence, outbox-row, and projection-delta writes;
- purpose-scoped projection and evidence reads;
- a JSON boundary with development identity headers; and
- a neutral Core conformance fixture and source-level dependency enforcement; and
- local tests and documentation for this narrow path.

The following are not implemented:

- explicit cell routing and configuration version;
- production OIDC and device proof;
- the complete authority dimensions and executable obligations;
- injected nondeterministic inputs for replay;
- commitments, scenarios, approvals, dispatch, and acknowledgement lifecycles;
- evidence objects, hashes, retention, and integrity reconciliation;
- an outbox publisher, inbox, retries, dead letters, and redrive;
- realtime delivery, local client state, offline reconciliation, or end-user surfaces;
- Edge observation buffering and promotion;
- Relay and Link delivery behavior;
- immutable production packaging, restore, failover, and load evidence.

## Programme sequence

### Gate 0: validate operational reality

Use the
[manufacturing exception and replan reality contract](reality-contracts/manufacturing-exception-replan-v0.1.md)
to obtain a named operational owner, validate normal and failure narratives, record decision
rights, and measure the baseline. Unvalidated narrative hypotheses do not authorize platform
abstractions.

### Gate 1: make the boundary executable

Separate manufacturing ownership from Core, add a neutral conformance fixture, and enforce
the dependency direction automatically.

Status on 2026-07-19: the code boundary, neutral fixture, and dependency check are implemented.
Removal rehearsal and completion of the legacy `site_id` to `scope_id` contract migration remain
before this gate is fully closed.

Exit evidence:

- removing the manufacturing package leaves Core schemas and tests valid;
- Core never interprets manufacturing payload fields or queries manufacturing tables; and
- a second neutral fixture uses the same capability, transaction, evidence, and event ports.

### Gate 2: complete the constitutional Core seam

Add cell context, production identity ports, versioned envelopes, full authority inputs,
executable obligations, deterministic input ports, evidence metadata, and durable delivery
contracts.

Exit evidence is defined by the capability, authority, replay, evidence, and delivery sections
of the [quality gates](../docs/QUALITY_GATES.md).

### Gate 3: complete the walking skeleton

Prove one validated device observation, one governed command, two distinct surfaces, one
delivery acknowledgement, and one complete evidence trail. The same contracts must survive
disconnect, replay, stale state, denial, and worker restart.

### Gate 4: prove operation before expansion

Promote one immutable artifact, restore an isolated cell, exercise workload isolation, and
measure the provisional service objectives. Only then begin the education and
content/commerce proof slices.

## Decisions still open

| Decision | Current position | Required owner or evidence |
| --- | --- | --- |
| Named operational owner | Unassigned | Manufacturing product leadership |
| Exact connection, command, fan-out, and telemetry envelope | Unmeasured | Product and platform load study |
| Launch regions and data residency | Unselected | Product, privacy, and legal decision |
| Offline authority per capability | Deny by default | Domain and local-safety review |
| First solver family and explanation standard | Deferred | Validated replan problem and benchmark |
| Identity provider | Port required; provider unselected | Security and launch integration decision |
| Relay launch channels | Unselected | Journey communication requirements |
| Evidence retention and legal hold | Unselected | Legal, privacy, and customer requirements |
| Actualis name clearance | Unconfirmed | Trademark and domain review |

## Stop rules

- Do not build a generic schema or capability compiler before repeated contracts justify it.
- Do not stabilize a Surface SDK before two materially different surfaces consume the same
  governed capability.
- Do not select a telemetry store, message broker, workflow engine, solver platform, or AI
  runtime without a measured quality scenario.
- Do not let the proof journey add manufacturing fields, schemas, or invariants to Core.
- Do not describe an outbox row as delivery, a JSON projection as an end-user surface, or a
  source-based VM evaluation as a production deployment.

## Review trigger

Review this baseline when any programme gate passes, a proof journey changes, an accepted ADR
is added or superseded, or production-shaped evidence overturns a v0.1 hypothesis.
