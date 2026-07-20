# Stock ADR 0001: Stock begins as a separate domain application

- Status: Accepted
- Date: 2026-07-19
- Owners: Actualis Engineering

## Context

Actualis needs a reusable physical-stock capability for education, manufacturing, and community
processes. Stock has stable domain meaning—items, accountable locations, quantity movements,
physical observations, and reconciliation—but it is not a constitutional Core lifecycle envelope.

Putting stock entities in `actualis_core` would contradict ADR 0003. Generalising them into a
resource, document, or workflow framework would reproduce the universal data and metadata-driven
behavior that this module is intended to avoid.

The umbrella already demonstrates the intended product-package seam through
`actualis_manufacturing`: Core owns the governed command, authority, receipt, evidence, and
transaction contracts; the product application owns its schemas, validation, effects, and events.

The Stock proposal uses an organisation as its initial operating scope. Core currently represents
authorization scope generically but does not yet implement the full cell-placement contract from
the architecture baseline.

## Decision

Create `actualis_stock` as a separate umbrella application following the same one-way dependency
rule as other product applications.

- The public Elixir namespace is `Actualis.Stock`.
- `actualis_stock` owns all future Stock schemas, migrations, rules, handlers, events, and tests.
- `actualis_core` does not depend on `actualis_stock` and cannot query Stock schemas.
- Stock consumes `Actualis.Capability.Handler` and the Core public contracts rather than creating a
  parallel command runtime.
- Co-location in the umbrella is a module and transaction boundary, not a claim that Stock belongs
  to Core or requires a microservice.

Phase 0 defines a canonical Stock scope containing `organisation_id`. A future Stock handler
returns that identifier as Core's opaque `authorization_scope_id`. This permits Core to evaluate a
scope grant without interpreting organisation or stock semantics.

An authorization-scope match is not proof of cell placement. A later Core cell-context contract
must bind the organisation scope to the trusted cell before production multi-tenant operation.

Stock reserves these capability identifiers:

- `stock.view_positions`
- `stock.manage_items`
- `stock.manage_locations`
- `stock.move_quantity`
- `stock.adjust_quantity`
- `stock.count_positions`
- `stock.review_count`
- `stock.manage_monitoring`

Future facts use past-tense, major-versioned names such as `stock.movement_posted.v1`. Stock
telemetry uses the `[:actualis, :stock]` prefix.

Phase 0 registers no Stock handler, adds no migration, persists no Stock state, exposes no web
route, and starts no Stock process. The test-only validation handler proves that Stock scope can be
canonicalized through the existing Core command contract without presenting an operation as
available.

## Consequences

- Core remains free of stock, warehouse, education, manufacturing, and community entities.
- Stock has a compile-time boundary that can later become a release or repository boundary.
- Phase 1 can implement governed Stock handlers inside the transaction already opened by Core.
- Future Stock migrations must be added to the root migration orchestration without moving their
  ownership into Core.
- Capability names remain unavailable until a concrete handler is implemented and registered.
- Cell isolation, verified production identity, and permission administration remain explicit
  prerequisites rather than implied Phase 0 behavior.

## Alternatives considered

### Add Stock to `actualis_core`

Rejected because physical stock is a product capability, not a reusable Core authority or evidence
envelope.

### Generalise Stock into a universal resource module

Rejected because it would recreate ERP-style universal entities, custom-field behavior, and
generic workflows.

### Start with a Stock microservice

Rejected because no independent scaling, release, security, or network-placement requirement has
been demonstrated, and a remote transaction would weaken the first ledger slice.

### Add a Stock-specific command envelope

Rejected because Core already owns the principal, device, purpose, capability, expected-version,
idempotency, authority, evidence, and transaction envelope.

## Validation and review

This decision is validated when:

- the umbrella compiles with a one-way `actualis_stock` to `actualis_core` dependency;
- a non-persisted Stock validation example passes through `Actualis.Capability.Command`;
- Core source contains no Stock entity or reference;
- capability and telemetry names are explicit and tested; and
- no Stock capability is registered before it has a real handler and acceptance tests.
