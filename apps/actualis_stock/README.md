# Actualis Stock

`actualis_stock` is the domain application for physical stock identity, accountable location,
movement, counting, reconciliation, and monitoring.

Its public Elixir context is `Actualis.Stock`.

Phase 0 implements only the application boundary, organisation-scope canonicalization, reserved
capability vocabulary, and telemetry naming. No Stock handler is registered, no Stock data is
persisted, and no operating interface is available.

See the [Stock technical reference](../../docs/technical/stock/README.md).
The package boundary is recorded in
[Stock ADR 0001](architecture/adr/0001-stock-domain-package-foundation.md).
