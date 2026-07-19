# Actualis Manufacturing

`actualis_manufacturing` is the first product application that consumes Actualis Core. It owns the
pallet-movement capability, manufacturing schemas and invariants, event payload, projections,
migrations, fixtures, and seed data.

The application implements `Actualis.Capability.Handler` and runs inside the transaction opened by
Core. It may use the Core delivery port to append an event, but Core does not interpret the event
payload or read manufacturing tables.

This is a reference proof, not a complete manufacturing product. Observation ingest, replanning,
operator and planner interfaces, external delivery, and production identity remain unavailable.

See the [manufacturing technical reference](../../docs/technical/manufacturing-reference/README.md).
