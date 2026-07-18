---
title: <Canonical component or contract name>
doc_type: technical
audience: agents_and_maintainers
kernel_area: <authority|manufacturing|execution|evidence|projection|foundation>
status: <implemented|partial|planned|deprecated>
source_paths:
  - <path>
test_paths:
  - <path or none>
paired_user_docs:
  - <path or none>
last_verified: <YYYY-MM-DD>
---

# <Canonical component or contract name>

## Current status

State what is implemented, partial, planned, deprecated, or unavailable. Name the boundary of this page.

## Purpose

Explain the stable problem this component solves and what it intentionally does not own.

## Contract

Document inputs, outputs, state transitions, public data shapes, and compatibility expectations. Prefer a small table or example when it is clearer than prose.

## Invariants and authorization

List rules that every implementation must preserve. Include capability, scope, purpose, field-level access, trust, and policy-version behavior where applicable.

## Execution and transaction flow

Describe ordering, transaction boundaries, idempotency, concurrency, events, projections, and externally visible effects. Use a Mermaid sequence or flow diagram only when it improves comprehension.

## Failure behavior

Document validation, denial, conflict, dependency, retry, and partial-failure behavior. State what is recorded and what the caller receives.

## Persistence and migration

Explain stored records, important constraints and indexes, lifecycle, retention, and migration considerations. Do not reproduce the full schema.

## Observability and operations

Describe evidence, receipts, logs, metrics, alerts, replay, and recovery. Mark missing capabilities as gaps.

## Verification

Name the tests and evidence that prove the contract. Include the last verification outcome; do not claim coverage that does not exist.

## Source map

| Concern | Source or test | What it proves |
|---|---|---|
| <concern> | `<path>` | <claim> |

## Known gaps and decisions

Separate confirmed current limitations from planned work. Link durable architectural decisions when available.

## Update triggers

List the source, contract, policy, UI, or operational changes that require this page to be re-verified.

