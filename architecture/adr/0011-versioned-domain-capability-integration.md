# ADR 0011: Versioned domain capabilities integrate through a Core transaction port

- Status: Proposed
- Date: 2026-07-19
- Owners: Actualis Engineering

## Context

[ADR 0003](0003-domain-packages-outside-core.md) keeps product entities and invariants outside
Actualis Core. [ADR 0006](0006-pallet-movement-application-module.md) made that direction executable
for the manufacturing reference application: `actualis_core` now exposes a domain-neutral handler
behaviour and configured registry, opens the database transaction, and calls a handler owned by the
separate `actualis_manufacturing` OTP application.

That seam is useful but intentionally partial. The current public key is only a capability string;
there is no immutable contract version or handler descriptor. Registry configuration is searched at
lookup time rather than validated into a duplicate-free startup registry. The runtime reads wall
time and generates identifiers directly. Authority uses a generic authorization scope, but Core has
no explicit cell contract, domain relationship-fact resolver, or long-running obligation lifecycle.

Participation will exercise relationships, multiple attestations, expiry, and sensitive evidence.
Those needs must be added as stable Core contracts rather than worked around with product tables,
generic ERP metadata, or callbacks hidden in Phoenix adapters.

## Decision

Evolve the existing handler seam into a small, versioned, statically composed contract. Core remains
the owner of governed invocation, authority evaluation, idempotency, transaction orchestration,
evidence metadata, and durable delivery intent. A domain package owns its input, relational model,
invariants, effects, facts, projections, and product evidence content.

### Invocation and descriptor

The stable Core invocation envelope carries, where applicable:

- one explicit `cell_id` and authenticated principal/device context;
- a capability identifier and separate immutable contract version;
- declared purpose and bounded client context;
- opaque domain input and expected aggregate versions;
- an idempotency key;
- validated evidence-object references; and
- request and correlation identifiers.

Each handler exposes a descriptor containing at least capability identity, contract version, handler
version, descriptor version, risk class, and declared relationship or obligation needs. Incompatible
contracts receive a new contract version. Handler implementation versions may change without
changing the external contract only when compatibility is preserved.

### Handler responsibilities

The handler contract has three responsibilities:

1. describe its stable contract and declared needs;
2. validate and canonicalize domain input without writes, network calls, wall-clock reads, generated
   identifiers, or other uncontrolled effects; and
3. execute the authorized domain decision inside the execution context supplied by Core.

The result contains domain versions, bounded effects, versioned domain facts, and evidence
references. Core validates the stable result envelope but does not interpret product fields.

Callbacks for generic before/after hooks are prohibited. A new callback requires evidence that at
least two independent domain handlers need the same stable lifecycle seam.

### Static registry

The composed release lists handler modules explicitly. Core builds an immutable registry at
application start, validates behaviour and descriptors, and rejects duplicate
`{capability, contract_version}` keys. Handler modules cannot be selected by caller input, uploaded,
or replaced at runtime.

### Transaction and deterministic inputs

For a fresh invocation, Core owns one short PostgreSQL transaction. It claims the idempotency
receipt, evaluates current authority, persists a rejection or pending obligation when applicable,
calls the domain handler, stores evidence metadata and outbox facts, completes the receipt, and
commits once.

The execution context supplies the evaluated clock, identifiers, policy/configuration versions, and
recorded external results. A handler writes only domain-owned tables and must not call network,
object-storage, messaging, solver, AI, or provider adapters while the transaction is open.

Cross-store work is completed and referenced before invocation, or delivered after commit through a
durable port. Historical replay uses recorded nondeterministic inputs and never repeats an external
side effect.

### Relationship facts and subjects

Core owns policy evaluation; a product owns the meaning and persistence of its relationships. A
narrow resolver returns effective, versioned facts requested for an exact cell, principal, target,
purpose, and evaluation time. Core records the referenced fact and does not query the product table
or interpret family, membership, coaching, or staffing semantics.

An authenticated principal is distinct from an opaque domain subject reference. This seam does not
introduce a universal person, party, participant, asset, or resource table in Core.

### Long-running obligations

An obligation such as a second signature, approval, step-up authentication, or expiry cannot keep a
database transaction open. Core persists pending state. Finalization is a new governed invocation
that re-evaluates current policy, relationships, obligation evidence, and expected domain versions.

### Package and migration composition

Domain packages are separately owned OTP applications with their own schema modules and migration
paths. They may be co-deployed in a modular monolith, but Core has no compile-time dependency on a
product package. The release pins its package artifacts, handlers, and migration order. Runtime
discovery or execution of downloaded migrations is outside this contract.

## Current implementation status — 2026-07-19

Implemented:

- `Actualis.Capability.Handler` separates product validation and execution from Core;
- `Actualis.Capability.Registry` resolves explicitly configured handler modules;
- `Actualis.CapabilityRuntime` owns one transaction for the handler, receipt, evidence, and durable
  event intent;
- `actualis_manufacturing` owns manufacturing schemas, invariants, projections, and tests; and
- a neutral Core fixture verifies execution, denial, replay, rollback, and dependency direction.

Still planned under this decision:

- immutable capability contract versions and validated descriptors;
- startup registry construction and duplicate rejection;
- explicit Core cell identity rather than only an opaque authorization scope;
- deterministic clock and identifier ports;
- a relationship-fact resolver;
- pending and finalized obligation semantics;
- bounded result/fact contracts and compatibility fixtures; and
- the complete cross-cell, version, concurrency, malformed-result, and delivery-replay conformance
  matrix.

## Consequences

- Product packages can remain explicit Phoenix/Ecto domains without becoming microservices.
- Core can support materially different products without importing their vocabulary.
- Important effects remain local, atomic, testable, and debuggable.
- Release composition and migration order are explicit operational responsibilities.
- A trusted in-process package can still consume BEAM or database resources; code review, pinning,
  budgets, telemetry, and conformance tests remain required.
- Participation cannot bypass missing contract pieces with direct writes from controllers,
  LiveViews, imports, or jobs.

## Alternatives rejected

### Universal entity, custom-field, or workflow storage

Rejected because it hides domain meaning, weakens relational constraints, and recreates a
traditional extensible ERP kernel.

### Generic persistence hooks

Rejected because ordering, transaction ownership, failure behavior, and compatibility become
implicit.

### A network service for every product domain

Rejected until independent resource, security, availability, placement, or release-cadence evidence
justifies distributed transactions and partial-failure costs.

### Let Core query product tables through the shared repository

Rejected because a shared PostgreSQL transaction does not transfer schema ownership.

## Validation

The decision is ready to accept after review of the exact descriptor, invocation, relationship,
obligation, result, and migration contracts. Implementation conforms when:

- Core compiles and migrates without any product package;
- two handler contract versions coexist and duplicate registrations fail at startup;
- Core imports no product implementation or vocabulary;
- allow, deny, pending obligation, replay, key conflict, stale version, concurrency, cross-cell,
  malformed result, and full rollback are covered by neutral tests;
- domain effect, receipt, evidence metadata, and outbox facts commit or roll back together;
- clock, identifiers, policy/configuration versions, and consequential external results are explicit
  and replayable; and
- architecture checks reject Core-to-product and adapter-to-Repo bypasses.

Reconsider static in-process composition only when measured evidence requires an independent
deployment boundary.
