# Actualis Core

`actualis_core` is the domain-neutral constitutional runtime. It owns governed capability
execution, authority, idempotency receipts, evidence metadata, and the durable delivery envelope.

Product applications register modules that implement `Actualis.Capability.Handler`. Core opens the
repository transaction and invokes the selected handler inside it, so domain effects, receipt,
evidence, and outbox intent commit or roll back together.

Core must not import product modules, inspect product payload fields, or query product tables. The
neutral conformance fixture under `test/support` verifies the handler boundary without manufacturing
vocabulary.

See the [Core v0 technical reference](../../docs/technical/core-kernel/README.md).
