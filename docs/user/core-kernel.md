# Understanding the Actualis core kernel

Status: API proof available; human-facing operator and supervisor screens are not implemented.

The kernel records who requested a pallet movement, which trusted device and business purpose were used, why current policy allowed or denied it, which pallet version was read, what effect committed, and which evidence remains.

A repeated request is safe when it has the same idempotency key and content. A changed request must use a new key. A stale screen or offline client receives a version conflict rather than overwriting newer work. Held or quarantined material cannot move through this capability.

Operator data omits supervisory detail. Supervisor data is a separate purpose-scoped view. Both are rechecked against current access when catching up after a disconnect.

There is no end-user UI to document or screenshot yet. The current interface is JSON for developers and integration testing.
