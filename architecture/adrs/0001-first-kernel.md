# ADR 0001: First constitutional kernel

- Status: accepted
- Date: 2026-07-18

Implement one Elixir/Phoenix umbrella with PostgreSQL authority. The first capability is `manufacturing.move_pallet`.

One transaction claims the idempotency key, evaluates authority, locks and validates the pallet version and invariants, records the movement and evidence, and appends a versioned outbox event plus operator and supervisor projection deltas.

The two projections are separate, field-filtered contracts. There is no universal resource table, broker, workflow engine, or simulated event sourcing.

The local identity headers are an adapter seam only. Production is blocked until they are replaced by verified OIDC principal resolution and authenticated device credentials.

Revisit PostgreSQL-backed delivery only when measured workloads violate a declared quality scenario.
