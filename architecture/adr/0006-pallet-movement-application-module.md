# ADR 0006: Pallet movement belongs to a manufacturing application module

Status: Accepted
Date: 2026-07-18
Owners: Actualis Engineering

## Context

The pallet-movement slice models sites, locations, pallets, material codes, quality states, movements, and operator and supervisor views. Those concepts and rules are specific to a manufacturing application.

The slice also exercises reusable Actualis Core behavior: governed capability invocation, authority evaluation, idempotency, optimistic concurrency, transactional effects, evidence, and an outbox. Exercising Core through a business capability does not make the business model part of the kernel. Describing `manufacturing.move_pallet` as the "first constitutional kernel" contradicts the Core boundary established by [ADR 0003](0003-domain-packages-outside-core.md).

## Decision

`manufacturing.move_pallet` and its supporting model belong to a manufacturing application module outside Actualis Core.

The manufacturing module owns:

- site, location, pallet, and movement schemas and migrations;
- pallet-movement inputs, business invariants, and effect handling;
- manufacturing event contracts and product-specific evidence content;
- operator, supervisor, and other manufacturing projections.

Core owns only the reusable contracts and runtime behavior used by that module, including:

- capability registration and governed invocation envelopes;
- principal, purpose, policy decision, and obligation handling;
- idempotency and expected-version protocols;
- transactional effect, evidence-metadata, and outbox envelopes;
- stable ports through which a domain module participates in the transaction.

The current co-location of manufacturing code under `apps/actualis_core` is an implementation limitation of the proof slice, not a Core ownership decision. It must not be used as precedent for adding manufacturing entities or rules to the kernel. The module should be extracted behind declared Core ports before the implementation is described as conforming to the Core architecture.

## Consequences

- The pallet slice remains useful as a business application proof, but it is not evidence that the constitutional kernel itself is complete.
- Core must not query manufacturing tables, interpret pallet fields, or publish manufacturing projections itself.
- Preserving one local transaction requires an explicit in-process transaction/effect port; separating ownership does not require a network service.
- Core conformance tests need a deliberately neutral fixture rather than a product module presented as kernel behavior.
- Existing code and documentation that label pallet semantics as Core carry migration work until the boundary is made executable.

## Alternatives considered

### Treat pallet movement as the first kernel capability

Rejected because it promotes one application's vocabulary, invariants, events, and views into a supposedly reusable foundation.

### Generalize pallets into a universal resource model

Rejected because it hides domain meaning in generic storage and recreates the universal entity model that Core explicitly excludes.

### Call the current manufacturing slice a conformance fixture

Rejected as a description of the current implementation. A conformance fixture must be minimal, neutral, and confined to test or evaluation code; this slice exposes real manufacturing semantics and product-shaped projections.

## Validation and review

The boundary is valid when:

- the manufacturing module can be removed without changing Core schemas or reusable contracts;
- Core accesses it only through declared capability, transaction, event, and evidence ports;
- Core does not interpret manufacturing payload fields or read manufacturing-owned tables;
- a second domain module can use the same Core ports without adopting manufacturing concepts; and
- dependency and conformance tests enforce those rules.

Reconsider a concept for Core ownership only when multiple independent domains require the same stable lifecycle semantics and a new ADR demonstrates that it is a reusable envelope rather than business vocabulary.
