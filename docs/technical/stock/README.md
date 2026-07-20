---
title: Actualis Stock foundation
doc_type: technical
audience: agents_and_maintainers
kernel_area: stock_domain_package
status: partial
source_paths:
  - apps/actualis_stock
  - apps/actualis_stock/architecture/adr/0001-stock-domain-package-foundation.md
test_paths:
  - apps/actualis_stock/test/actualis/stock/phase0_test.exs
paired_user_docs:
  - docs/user/stock/README.md
last_verified: 2026-07-19
---

# Actualis Stock foundation

## Current status

Phase 0 is partially implemented. The workspace contains a separate `actualis_stock` application,
a public `Actualis.Stock` boundary, canonical organisation-scope validation, eight reserved
capability identifiers, and telemetry names.

There are no Stock tables, persisted items, locations, balances, movements, stocktakes, registered
handlers, HTTP routes, or user interface. A reserved capability name does not mean that the
operation is available.

## Purpose and ownership

Stock will own physical stock identity, accountable location, quantity movement, physical
observation, and reconciliation. Education, manufacturing, and community applications own the
processes that cause or consume those facts.

Stock is a product application, not part of Actualis Core. The compile-time dependency points from
`actualis_stock` to `actualis_core`; Core must not depend on Stock or interpret Stock fields.

The package boundary and scope decision are recorded in
[Stock ADR 0001](../../../apps/actualis_stock/architecture/adr/0001-stock-domain-package-foundation.md).

## Public contract

`Actualis.Stock` is the public entry point. Phase 0 exposes:

```elixir
Actualis.Stock.new_scope(attributes)
Actualis.Stock.capabilities()
```

`Actualis.Stock.Scope` accepts the external string-keyed shape
`%{"organisation_id" => canonical_uuid}`. It rejects missing, atom-keyed, malformed, uppercase, or
raw 16-byte UUID input rather than accepting multiple canonical representations.

A future Stock handler passes the organisation identifier to Core as
`authorization_scope_id` and retains `%{"organisation_id" => id}` in the product scope. Core can
evaluate authority without knowing what an organisation means.

Constructing a scope performs no authentication, authority decision, cell placement, persistence,
or telemetry. The Core command already owns principal, device, purpose, capability,
expected-version, idempotency, evidence, and transaction fields; Stock does not duplicate them.

## Capability vocabulary

| Identifier | Intended phase | Availability |
|---|---:|---|
| `stock.view_positions` | 1 | Planned |
| `stock.manage_items` | 1 | Planned |
| `stock.manage_locations` | 1 | Planned |
| `stock.move_quantity` | 1 | Planned |
| `stock.adjust_quantity` | 1 | Planned |
| `stock.count_positions` | 2 | Planned |
| `stock.review_count` | 2 | Planned |
| `stock.manage_monitoring` | 3 | Planned |

These strings are machine contracts, not display labels. They are not present in the configured
Core handler registry in Phase 0.

## Invariants and authorization

- Every future Stock handler supplies one canonical organisation authorization scope.
- Scope construction never substitutes for Core authority or trusted cell resolution.
- Stock uses the existing Core command and handler contracts.
- Stock capability identifiers follow `<context>.<verb>_<object>`.
- Stock must not introduce a universal resource, behavioral custom fields, or a workflow engine.
- Core cannot import Stock modules, read Stock tables, or interpret Stock payloads.
- Other applications use the public context rather than Stock schemas.

## Execution and transaction flow

No Stock transaction exists in Phase 0. The implemented path is validation only:

```text
external scope → Actualis.Stock → canonical Stock scope
                                     ↓
                       Core command validation example
```

The test-only handler proves compatibility with `Actualis.Capability.Command`; it is not registered
and its `execute/2` callback performs no effect. Phase 1 handlers will run inside the transaction
opened by Core and will own their Stock invariants and persistence.

## Failure behavior

`new_scope/1` returns `{:ok, scope}` for canonical input and
`{:error, :invalid_stock_scope}` for all ordinary invalid shapes. It does not raise for external
validation failures.

Capability lookup uses `Actualis.Stock.Capabilities.known?/1` and returns `false` for unknown names.

## Persistence and migration

Phase 0 adds no migration or table. Future Stock migrations belong under `actualis_stock`. When the
first migration is added, the root `actualis.migrate` task must include the Stock migration path
while the single PostgreSQL writer remains authoritative.

## Observability and operations

`Actualis.Stock.Telemetry` reserves:

- `[:actualis, :stock, :command, :start]`
- `[:actualis, :stock, :command, :stop]`
- `[:actualis, :stock, :command, :exception]`

Nothing emits these events yet. Later phases must document measurements and low-cardinality
metadata before instrumenting real commands. There is no Stock worker, alert, or recovery
procedure.

## Verification

`apps/actualis_stock/test/actualis/stock/phase0_test.exs` verifies:

- canonical scope construction and external representation;
- rejection of ambiguous or internally keyed scope input;
- compatibility with the Core command and handler contract without persistence;
- the exact capability and telemetry vocabulary; and
- the absence of a Core source dependency on Stock.

## Source map

| Concern | Source or test | What it proves |
|---|---|---|
| Public boundary | `apps/actualis_stock/lib/actualis/stock.ex` | Current context entry point |
| Organisation scope | `apps/actualis_stock/lib/actualis/stock/scope.ex` | Canonical scope shape and failure result |
| Capabilities | `apps/actualis_stock/lib/actualis/stock/capabilities.ex` | Reserved authorization identifiers |
| Telemetry | `apps/actualis_stock/lib/actualis/stock/telemetry.ex` | Reserved instrumentation names |
| Package dependency | `apps/actualis_stock/mix.exs` | Separate app and one-way Core dependency |
| Tests | `apps/actualis_stock/test/actualis/stock/phase0_test.exs` | Executable Phase 0 contract |

## Known gaps and next gate

- The Core architecture requires cell context, but trusted cell placement is not implemented in the
  current command envelope.
- Production principal and device authentication remain unavailable.
- No Stock operation, schema, event, projection, or UI exists.
- Permission identifiers are reserved but are not registered or grantable through an
  administration surface.
- Telemetry events are named but are not emitted.

The first Phase 1 slice should implement cell/organisation-scoped items and accountable locations
through concrete governed handlers. It must add no generic resource model and must not register a
handler until its domain behavior and authorization tests exist.

## Update triggers

Re-verify this page when Stock dependencies, scope fields, capability identifiers, telemetry names,
handler registrations, tenancy/cell contracts, migrations, or Phase 1 public functions change.
