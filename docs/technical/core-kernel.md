# Core-kernel technical reference

This compatibility entry point now routes to two ownership-specific references:

- [Actualis Core v0](core-kernel/README.md) covers the domain-neutral capability runtime,
  authority, receipts, evidence, delivery envelope, migrations, and conformance fixture.
- [Manufacturing reference application](manufacturing-reference/README.md) covers pallet movement,
  product invariants, projections, and the governed HTTP proof.

The split is intentional: Core opens and governs one transaction, while the registered product
handler owns product semantics and effects.
