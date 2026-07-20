---
title: Manufacturing reference application
doc_type: technical
audience: agents_and_maintainers
kernel_area: manufacturing_reference
status: partial
source_paths:
  - apps/actualis_manufacturing
  - apps/actualis_web
  - evals/phase0
  - contracts/capabilities/manufacturing.move_pallet.v0.json
  - contracts/events/manufacturing.pallet_moved.v1.json
test_paths:
  - apps/actualis_manufacturing/test
  - apps/actualis_web/test
paired_user_docs:
  - docs/user/core-kernel/README.md
last_verified: 2026-07-19
---

# Manufacturing reference application

## Current status

`actualis_manufacturing` is a partial product application that consumes Actualis Core contracts.
It is not part of the constitutional kernel.

The application owns:

- site, location, pallet, and movement schemas;
- `manufacturing.move_pallet` input validation and business invariants;
- the `manufacturing.pallet_moved.v1` event payload;
- operator and supervisor snapshot and delta projections;
- manufacturing fixtures, behavior tests, and demo seed data; and
- the manufacturing migration path.

The application is co-deployed in the umbrella and uses the Core repository transaction. This is a
module boundary, not a service boundary.

## Core integration

`ActualisManufacturing.MovePallet` implements `Actualis.Capability.Handler`. Core validates the
common envelope and owns the transaction, receipt, authority decision, evidence metadata, and
generic outbox append. The handler validates `site_id` and all pallet fields, locks and updates its
tables, creates the manufacturing event payload, and writes its projections.

The root configuration registers the handler for `manufacturing.move_pallet`. The web controller
calls the `ActualisManufacturing` public context rather than Core persistence or manufacturing
schemas.

## Pallet movement invariants

The handler locks the requested pallet in its site and checks, in order:

1. the expected pallet version matches;
2. the claimed source is still current;
3. the quality status is `released`;
4. the destination is active in the same site; and
5. source and destination differ.

A successful movement updates the pallet version and location, inserts movement history, appends
the manufacturing outbox event through Core, and writes operator and supervisor deltas. Core then
records evidence and completes the receipt in the same transaction.

Stable rejection codes remain `pallet_not_found`, `version_conflict`,
`source_location_conflict`, `quality_status_blocks_move`, `invalid_destination`, and
`destination_unchanged`.

## Projections

The manufacturing application owns `ActualisManufacturing.Projection`. Snapshot and delta reads
are reauthorized through Core authority using the site as the generic authorization scope.

Operator and supervisor payloads remain distinct. Each response is reduced to fields allowed by
the current grant. Deltas use the durable serial cursor, expire after eight hours, exclude revoked
rows, and return at most 500 rows per request.

## Persistence and migrations

The original immutable bootstrap migration created the manufacturing tables while the proof slice
was still inside Core. That history is retained. The manufacturing migration path now records
ownership of those tables and owns every future manufacturing schema change.

The authority scope expansion keeps a nullable legacy `site_id` column during mixed-version
deployment, but Core authority tables no longer have foreign keys to manufacturing tables.
Manufacturing seeds and fixtures temporarily write both `scope_id` and the legacy value. A later
contract migration removes the legacy column after old code is retired.

## Tests

The manufacturing suite verifies:

- atomic domain, receipt, evidence, outbox, and projection writes;
- identical idempotent replay and changed-payload conflicts;
- stale-version and quality-hold rejection without movement;
- purpose denial with retained evidence;
- projection field filtering and cursor catch-up;
- evidence reconstruction; and
- receipt completion.

The web suite separately verifies identity enforcement, transport execution and replay, and the
OpenAPI route.

The Phase 0 fixture suite verifies that the committed workload inputs are explicitly synthetic,
deterministic, unique where required, and include duplicate, reconnect, and out-of-order cases. The
command benchmark is an evaluation harness, not a production performance claim.

## Current gaps

- Production identity and device authentication are absent.
- Observation ingest and validation do not exist; database location is not proof of physical truth.
- Quality release, quarantine, replanning, approval, dispatch, and acknowledgement are not
  implemented.
- Projection delivery is JSON-only; no realtime or offline client exists.
- Outbox publication and external delivery are absent.
- No human-facing operator or planner surface exists.

These gaps are governed by the
[manufacturing exception and replan reality contract](../../../architecture/reality-contracts/manufacturing-exception-replan-v0.1.md).

## Source map

| Concern | Source |
| --- | --- |
| Public manufacturing context | [`actualis_manufacturing.ex`](../../../apps/actualis_manufacturing/lib/actualis_manufacturing.ex) |
| Governed pallet handler | [`move_pallet.ex`](../../../apps/actualis_manufacturing/lib/actualis_manufacturing/move_pallet.ex) |
| Product schemas | [`actualis_manufacturing/`](../../../apps/actualis_manufacturing/lib/actualis_manufacturing) |
| Product projections | [`projection.ex`](../../../apps/actualis_manufacturing/lib/actualis_manufacturing/projection.ex) |
| Migration ownership | [`migrations/`](../../../apps/actualis_manufacturing/priv/repo/migrations) |
| Behavior tests | [`move_pallet_test.exs`](../../../apps/actualis_manufacturing/test/actualis_manufacturing/move_pallet_test.exs) |
| Phase 0 evaluation inputs | [`evals/phase0/`](../../../evals/phase0) |
| Transport adapter | [`actualis_controller.ex`](../../../apps/actualis_web/lib/actualis_web/controllers/actualis_controller.ex) |

Verification on 2026-07-19: all 12 manufacturing and 5 web tests passed as part of the 32-test
umbrella suite, which also includes Core and Stock boundary tests.
